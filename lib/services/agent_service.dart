import 'package:dart_agent_core/dart_agent_core.dart';

import '../models/ai_profile.dart';

/// Agent 流式事件（供 UI 展示：增量文本 + 工具调用步骤）
sealed class AgentStreamEvent {}
class AgentTextEvent extends AgentStreamEvent {
  final String text;
  AgentTextEvent(this.text);
}
class AgentToolEvent extends AgentStreamEvent {
  final int toolCount;
  AgentToolEvent(this.toolCount);
}
class AgentFinishedEvent extends AgentStreamEvent {
  final String finalText;
  AgentFinishedEvent(this.finalText);
}

/// Agent 服务（阶段0 实验版）：封装 dart_agent_core 的 StatefulAgent，
/// 复用现有 AiProfile（baseUrl + apiKey + model）。
class AgentService {
  final AiProfile profile;
  final String model;
  final String sessionId;
  final AgentState state;
  late final StatefulAgent _agent;

  AgentService({
    required this.profile,
    required this.model,
    required this.sessionId,
    required this.state,
  }) {
    _agent = StatefulAgent(
      name: 'xumi-agent',
      client: OpenAIClient(
        apiKey: profile.apiKey,
        baseUrl: profile.normalizedBaseUrl,
      ),
      modelConfig: ModelConfig(model: model, temperature: 0.7),
      state: state,
      tools: [
        Tool(
          name: 'calculator',
          description: '计算一个数学表达式，返回计算结果',
          parameters: {
            'type': 'object',
            'properties': {
              'expression': {
                'type': 'string',
                'description': '要计算的数学表达式，如 1+2*3',
              },
            },
            'required': ['expression'],
          },
          executable: (Map args) =>
              _calc(args['expression'] as String? ?? ''),
        ),
        Tool(
          name: 'current_time',
          description: '获取当前本地时间',
          parameters: {'type': 'object', 'properties': {}},
          executable: (_) => DateTime.now().toIso8601String(),
        ),
      ],
    );
  }

  static String _calc(String expr) {
    if (!RegExp(r'^[0-9+\-*/().\s]+$').hasMatch(expr)) {
      return '表达式包含不支持的字符';
    }
    try {
      return _evaluate(expr.replaceAll(' ', '')).toString();
    } catch (e) {
      return '计算失败：$e';
    }
  }

  static double _evaluate(String src) {
    final p = _ExprParser(src);
    final v = p.parseAdd();
    if (!p.atEnd) throw const FormatException('多余字符');
    return v;
  }

  /// 一次 Agent 对话：把 runStream 的 StreamingEvent 映射成 UI 事件流
  Stream<AgentStreamEvent> chatStream(String userText) {
    final sb = StringBuffer();
    return _agent.runStream([UserMessage.text(userText)]).map((event) {
      switch (event.eventType) {
        case StreamingEventType.modelChunkMessage:
          final t = event.data as String;
          sb.write(t);
          return AgentTextEvent(t);
        case StreamingEventType.functionCallRequest:
          return AgentToolEvent((event.data as List).length);
        case StreamingEventType.fullModelMessage:
          return AgentFinishedEvent(sb.toString());
        default:
          return AgentTextEvent('');
      }
    });
  }

  /// 把状态（含历史/记忆）持久化到本地
  Future<void> saveState() async {
    final storage = FileStateStorage('agent_state');
    await storage.save(state);
  }
}

/// 极简安全表达式解析器（递归下降，仅支持 + - * / ( ) 数字）
class _ExprParser {
  final String src;
  int pos = 0;
  _ExprParser(this.src);
  bool get atEnd => pos >= src.length;

  double parseAdd() {
    var v = parseMul();
    while (pos < src.length) {
      final c = src[pos];
      if (c == '+') {
        pos++;
        v += parseMul();
      } else if (c == '-') {
        pos++;
        v -= parseMul();
      } else {
        break;
      }
    }
    return v;
  }

  double parseMul() {
    var v = parseAtom();
    while (pos < src.length) {
      final c = src[pos];
      if (c == '*') {
        pos++;
        v *= parseAtom();
      } else if (c == '/') {
        pos++;
        v /= parseAtom();
      } else {
        break;
      }
    }
    return v;
  }

  double parseAtom() {
    if (pos < src.length && src[pos] == '(') {
      pos++;
      final v = parseAdd();
      if (pos < src.length && src[pos] == ')') pos++;
      return v;
    }
    final start = pos;
    while (pos < src.length && (_digit(src[pos]) || src[pos] == '.')) {
      pos++;
    }
    if (start == pos) throw const FormatException('非法数字');
    return double.parse(src.substring(start, pos));
  }

  static bool _digit(String c) {
    final u = c.codeUnitAt(0);
    return u >= 48 && u <= 57;
  }
}
