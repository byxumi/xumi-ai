import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../models/ai_profile.dart';
import '../models/chat_conversation.dart';

/// API 异常
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// SSE 解析结果
enum SseResult { continue_reading, done }

/// OpenAI 兼容 Chat Completions 客户端
/// 支持 SSE 流式输出
class OpenAIClient {
  final Dio _dio;

  OpenAIClient()
      : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 120),
          sendTimeout: const Duration(seconds: 60),
          headers: {'Content-Type': 'application/json'},
        ));

  /// 拉取模型列表（可选，用于配置页自动填充）
  Future<List<String>> fetchModels(AiProfile profile) async {
    try {
      final resp = await _dio.get(
        profile.modelsEndpoint,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${profile.apiKey}',
          },
        ),
      );
      final data = resp.data;
      if (data is Map<String, dynamic> && data['data'] is List) {
        return (data['data'] as List)
            .whereType<Map<String, dynamic>>()
            .map((e) => e['id'].toString())
            .where((id) => id.isNotEmpty && !id.startsWith('_'))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// 发起一次流式对话
  /// [history] 传入的会话消息（OpenAI 格式需要转成 map）
  /// 返回回调产生的内容，可通过 [onDelta] 逐段推送（SSE）
  Future<void> streamChat({
    required AiProfile profile,
    required String model,
    required List<ChatMessage> history,
    required void Function(String delta) onDelta,
    required void Function(String full) onDone,
    required void Function(String err) onError,
  }) async {
    // 组装 OpenAI 消息
    final messages = <Map<String, dynamic>>[
      for (final m in history)
        if (m.content.trim().isNotEmpty)
          {'role': m.role.name, 'content': m.content},
    ];

    String endpoint = profile.chatEndpoint;

    try {
      final resp = await _dio.post<ResponseBody>(
        endpoint,
        data: {
          'model': model,
          'messages': messages,
          'stream': true,
          'temperature': 0.7,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer ${profile.apiKey}',
          },
          responseType: ResponseType.stream,
        ),
      );

      // SSE 流式解析：逐行读取，行可能跨多个网络 chunk，需缓存不完整尾部
      final buffer = StringBuffer();
      var leftover = '';
      await for (final chunk in resp.data!.stream) {
        leftover += utf8.decode(chunk, allowMalformed: true);
        final lines = leftover.split('\n');
        if (lines.isNotEmpty) {
          leftover = lines.removeLast();
        }
        var stopped = false;
        for (final rawLine in lines) {
          if (_parseSseLine(rawLine, buffer, onDelta) == SseResult.done) {
            stopped = true;
            break;
          }
        }
        if (stopped) break;
      }
      // 处理最后一个无换行的 chunk
      if (leftover.trim().isNotEmpty) {
        _parseSseLine(leftover, buffer, onDelta);
      }
      onDone(buffer.toString());
    } on DioException catch (e) {
      String err = _friendlyDioError(e);
      onError(err);
    } catch (e) {
      onError('请求失败：$e');
    }
  }

  /// 解析一行 SSE 数据，返回是否到达 [DONE]
  SseResult _parseSseLine(
      String line, StringBuffer buffer, void Function(String) onDelta) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || !trimmed.startsWith('data:')) {
      return SseResult.continue_reading;
    }
    final payload = trimmed.substring(5).trim();
    if (payload == '[DONE]') return SseResult.done;
    try {
      final json = jsonDecode(payload) as Map<String, dynamic>;
      final choices = json['choices'] as List<dynamic>? ?? [];
      if (choices.isEmpty) return SseResult.continue_reading;
      final first = choices.first as Map<String, dynamic>;
      final delta = (first['delta'] as Map<String, dynamic>?)?['content'];
      if (delta is String && delta.isNotEmpty) {
        buffer.write(delta);
        onDelta(delta);
      }
    } catch (_) {
      // 忽略无法解析的 chunk
    }
    return SseResult.continue_reading;
  }

  /// 把 DioException 转成友好错误信息
  String _friendlyDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return '网络超时，请检查网络或接口地址';
    }
    if (e.type == DioExceptionType.connectionError) {
      return '无法连接服务器（${e.message ?? ''}）';
    }
    final resp = e.response;
    if (resp != null) {
      final status = resp.statusCode ?? 0;
      if (status == 401 || status == 403) {
        return '认证失败：API Key 无效或无权限';
      }
      if (status == 404) {
        return '接口不存在（404）：请检查 Base URL 是否正确';
      }
      if (status == 429) {
        return '请求过于频繁（429）：API 限流，请稍后再试';
      }
      if (status == 400) {
        final data = resp.data;
        if (data is String) return '请求错误（400）：$data';
        if (data is Map && data['error'] != null) {
          final err = data['error'];
          if (err is Map && err['message'] != null) {
            return '模型请求被拒：${err['message']}';
          }
          return '请求错误（400）：$err';
        }
        return '请求错误（400）：请检查模型名或参数';
      }
      if (status >= 500) {
        return '服务器错误（$status）：请稍后再试';
      }
      return '请求失败（$status）';
    }
    return '网络错误：${e.message ?? ''}';
  }

  /// 非流式一次性对话（备用，测试连通性）
  Future<String> quickChat({
    required AiProfile profile,
    required String model,
    required String prompt,
  }) async {
    try {
      final resp = await _dio.post(
        profile.chatEndpoint,
        data: {
          'model': model,
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
          'stream': false,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer ${profile.apiKey}',
          },
        ),
      );
      final data = resp.data as Map<String, dynamic>;
      final choices = data['choices'] as List<dynamic>? ?? [];
      if (choices.isEmpty) return '';
      final first = choices.first as Map<String, dynamic>;
      return (first['message'] as Map<String, dynamic>?)?['content']
              ?.toString() ??
          '';
    } on DioException catch (e) {
      throw ApiException(_friendlyDioError(e), statusCode: e.response?.statusCode);
    }
  }
}