import 'package:dart_agent_core/dart_agent_core.dart';

import '../models/ai_profile.dart';
import 'memory_store.dart';

/// Agent 流式事件（供 UI 展示：增量文本 + 工具调用步骤）
sealed class AgentStreamEvent {}
class AgentTextEvent extends AgentStreamEvent {
  final String text;
  AgentTextEvent(this.text);
}
class AgentToolEvent extends AgentStreamEvent {
  final String toolName;
  final int toolCount;
  AgentToolEvent({required this.toolName, required this.toolCount});
}
class AgentFinishedEvent extends AgentStreamEvent {
  final String finalText;
  AgentFinishedEvent(this.finalText);
}

/// Agent 服务：封装 dart_agent_core 的 StatefulAgent，
/// 复用现有 AiProfile（baseUrl + apiKey + model），内置工具 + 本地记忆。
class AgentService {
  final AiProfile profile;
  final String model;
  final String sessionId;
  final AgentState state;
  final MemoryStore memory;
  late final StatefulAgent _agent;

  AgentService({
    required this.profile,
    required this.model,
    required this.sessionId,
    required this.state,
    required this.memory,
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
          description: '计算一个数学表达式，返回计算结果（如 1+2*3、10/4、2*(3+5)）',
          parameters: {
            'type': 'object',
            'properties': {
              'expression': {
                'type': 'string',
                'description': '要计算的数学表达式',
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
        Tool(
          name: 'remember',
          description: '把用户告诉你的一个重要偏好或事实记下来，以后一直记得',
          parameters: {
            'type': 'object',
            'properties': {
              'key': {'type': 'string', 'description': '记忆条目名称，如"称呼"'},
              'value': {'type': 'string', 'description': '记忆内容，如"叫我阿明"'},
            },
            'required': ['key', 'value'],
          },
          executable: (Map args) => memory.remember(
              args['key'] as String? ?? '', args['value'] as String? ?? ''),
        ),
        Tool(
          name: 'recall',
          description: '回忆之前记住的信息（按 key 查找）',
          parameters: {
            'type': 'object',
            'properties': {
              'key': {'type': 'string', 'description': '要查找的记忆条目名称'},
            },
            'required': ['key'],
          },
          executable: (Map args) => memory.recall(args['key'] as String? ?? ''),
        ),
        Tool(
          name: 'list_memory',
          description: '列出所有记住的信息',
          parameters: {'type': 'object', 'properties': {}},
          executable: (_) => memory.listAll(),
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
      return '计算失败：' + e.toString();
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
          final calls = event.data as List;
          String name = '';
          if (calls.isNotEmpty) {
            final first = calls.first;
            name = (first is FunctionCall)
                ? first.name
                : (first is Map && first['name'] != null
                    ? first['name'].toString()
                    : '');
          }
          return AgentToolEvent(toolName: name, toolCount: calls.length);
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
