import 'dart:math';

import 'package:dart_agent_core/dart_agent_core.dart'
    hide OpenAIClient;
import 'package:flutter/foundation.dart';

import '../models/ai_profile.dart';
import '../models/chat_conversation.dart';
import '../services/agent_service.dart';
import '../services/chat_store.dart';
import '../services/memory_store.dart';
import '../services/openai_client.dart';
import '../services/settings_service.dart';

/// 全局应用状态（Provider ChangeNotifier）
class AppState extends ChangeNotifier {
  final SettingsService settings;
  final ChatStore store;
  final OpenAIClient api = OpenAIClient();
  final MemoryStore memory = MemoryStore();

  // ---------- 档案 / 会话 ----------
  List<AiProfile> _profiles = [];
  List<ChatConversation> _conversations = [];
  Map<String, List<ChatMessage>> _messages = {};

  // 当前打开的会话
  String? _activeConvId;

  // 生成状态
  bool _isGenerating = false;
  String _streamed = '';

  AppState({required this.settings, required this.store});

  // ---------- getters ----------

  List<AiProfile> get profiles => _profiles;
  AiProfile? get activeProfile => settings.activeProfile;
  String get activeModel => settings.effectiveModel;
  List<ChatConversation> get conversations => _conversations;
  String? get activeConvId => _activeConvId;
  bool get isGenerating => _isGenerating;

  ChatConversation? get activeConversation {
    for (final c in _conversations) {
      if (c.id == _activeConvId) return c;
    }
    return null;
  }

  List<ChatMessage> get activeMessages =>
      _messages[_activeConvId ?? ''] ?? const [];

  /// 是否有可用的接口配置
  bool get hasApi => activeProfile != null && activeModel.isNotEmpty;

  /// Agent 模式开关（走工具调用 + 记忆的 Agent 通道）
  bool get agentEnabled => settings.agentEnabled;
  Future<void> setAgentEnabled(bool value) async {
    await settings.saveAgentEnabled(value);
    notifyListeners();
  }

  /// 联网搜索 Key（预留，模型自带联网时无需填写）
  String get searchApiKey => settings.searchApiKey;
  Future<void> setSearchApiKey(String value) async {
    await settings.saveSearchApiKey(value);
    notifyListeners();
  }

  // ---------- 初始化 ----------

  Future<void> init() async {
    await settings.load();
    await store.load();
    await memory.init();
    _profiles = [...settings.profiles];
    _conversations = await store.loadConversations();
    // 恢复上次会话
    for (final c in _conversations) {
      _messages[c.id] = await store.loadMessages(c.id);
    }
    if (_conversations.isNotEmpty) {
      _activeConvId = _conversations.first.id;
    }
    notifyListeners();
  }

  // ---------- 档案管理 ----------

  Future<void> addProfile(AiProfile profile) async {
    _profiles.insert(0, profile);
    await _saveProfiles();
    if (settings.activeProfileId.isEmpty) {
      await settings.saveActiveProfile(profile.id);
      if (profile.models.isNotEmpty) {
        await settings.saveActiveModel(
            profile.defaultModel ?? profile.models.first);
      }
    }
    notifyListeners();
  }

  Future<void> updateProfile(AiProfile profile) async {
    final i = _profiles.indexWhere((p) => p.id == profile.id);
    if (i >= 0) {
      _profiles[i] = profile;
      await _saveProfiles();
      notifyListeners();
    }
  }

  Future<void> removeProfile(String id) async {
    _profiles.removeWhere((p) => p.id == id);
    await _saveProfiles();
    if (settings.activeProfileId == id) {
      await settings.saveActiveProfile(_profiles.isNotEmpty
          ? _profiles.first.id
          : '');
      await settings.saveActiveModel('');
    }
    notifyListeners();
  }

  Future<void> _saveProfiles() async {
    await settings.saveProfiles(_profiles);
  }

  // ---------- 切换档案 / 模型 ----------

  Future<void> selectProfile(String profileId) async {
    await settings.saveActiveProfile(profileId);
    final p = settings.activeProfile;
    if (p != null && p.models.isNotEmpty) {
      await settings.saveActiveModel(p.defaultModel ?? p.models.first);
    }
    notifyListeners();
  }

  Future<void> selectModel(String model) async {
    await settings.saveActiveModel(model);
    notifyListeners();
  }

  // ---------- 会话管理 ----------

  Future<ChatConversation> createConversation() async {
    final conv = ChatConversation(
      id: _genId(),
      title: '新对话',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      profileId: settings.activeProfileId,
      model: settings.effectiveModel,
    );
    _conversations.insert(0, conv);
    _messages[conv.id] = [];
    await _persistConversations();
    _activeConvId = conv.id;
    notifyListeners();
    return conv;
  }

  Future<void> switchConversation(String id) async {
    if (_activeConvId == id) return;
    _activeConvId = id;
    if (!_messages.containsKey(id)) {
      _messages[id] = await store.loadMessages(id);
    }
    notifyListeners();
  }

  Future<void> deleteConversation(String id) async {
    _conversations.removeWhere((c) => c.id == id);
    _messages.remove(id);
    await store.deleteMessages(id);
    await _persistConversations();
    if (_activeConvId == id) {
      _activeConvId =
          _conversations.isNotEmpty ? _conversations.first.id : null;
    }
    notifyListeners();
  }

  Future<void> renameConversation(String id, String title) async {
    final i = _conversations.indexWhere((c) => c.id == id);
    if (i >= 0) {
      _conversations[i].title = title;
      await _persistConversations();
      notifyListeners();
    }
  }

  Future<void> _persistConversations() async {
    await store.saveConversations(_conversations);
  }

  // ---------- 发送消息 ----------

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || _isGenerating) return;

    // 确保有会话
    if (_activeConvId == null) {
      await createConversation();
    }
    final convId = _activeConvId!;
    final conv = activeConversation;

    // 更新会话标题为第一句话（截断）
    if (conv != null && (conv.title == '新对话' || conv.title.isEmpty)) {
      final t = text.trim();
      conv.title = t.length > 18 ? '${t.substring(0, 18)}…' : t;
      await _persistConversations();
    }

    // 追加用户消息
    final userMsg = ChatMessage(
      id: _genId(),
      role: ChatRole.user,
      content: text.trim(),
      timestamp: DateTime.now(),
    );
    final msgs = _messages[convId] ?? [];
    msgs.add(userMsg);
    _messages[convId] = msgs;
    writeThrough(convId);

    // 追加待生成的 assistant 空消息
    final assistantMsg = ChatMessage(
      id: _genId(),
      role: ChatRole.assistant,
      content: '',
      timestamp: DateTime.now(),
      isStreaming: true,
    );
    msgs.add(assistantMsg);
    _messages[convId] = msgs;

    _isGenerating = true;
    notifyListeners();

    // 发送历史（不含刚才的空 assistant 结尾，仅此前完整消息）
    final history = _messages[convId]!
        .where((m) => m.id != assistantMsg.id)
        .toList();

    final profile = activeProfile;
    if (profile == null) {
      _finishError(assistantMsg.id, convId, '请先在「设置」中配置 API 接口');
      return;
    }
    final model = activeModel;

    // Agent 模式：工具调用 + 记忆（可在设置里开关）
    if (agentEnabled) {
      await _sendAgent(
          convId, assistantMsg.id, profile, model, history, text.trim());
      return;
    }

    await api.streamChat(
      profile: profile,
      model: model,
      history: history,
      onDelta: (d) {
        _streamed += d;
        final idx = _messages[convId]!
            .indexWhere((m) => m.id == assistantMsg.id);
        if (idx >= 0) {
          _messages[convId]![idx] =
              _messages[convId]![idx].copyWith(content: _streamed);
          writeThrough(convId);
        }
        notifyListeners();
      },
      onDone: (full) {
        _streamed = '';
        final idx = _messages[convId]!
            .indexWhere((m) => m.id == assistantMsg.id);
        if (idx >= 0) {
          _messages[convId]![idx] = _messages[convId]![idx].copyWith(
            content: full.isEmpty ? '（无回复）' : full,
            isStreaming: false,
            isError: false,
            model: model,
          );
        }
        _isGenerating = false;
        writeThrough(convId);
        _touchConversation(convId);
        notifyListeners();
      },
      onError: (err) {
        _streamed = '';
        _finishError(assistantMsg.id, convId, err);
      },
    );
  }

  /// 按会话缓存的 Agent（保持上下文连续性）
  final Map<String, AgentService> _agents = {};

  /// 已注入 Agent 历史的用户消息（按会话去重）
  final Map<String, Set<String>> _injectedHistory = {};

  /// Agent 模式发送：走 dart_agent_core（工具调用 + 记忆 + 上下文）
  Future<void> _sendAgent(
    String convId,
    String assistantMsgId,
    AiProfile profile,
    String model,
    List<ChatMessage> history,
    String userText,
  ) async {
    // 按会话创建/复用 Agent，保持上下文
    final agent = _agents.putIfAbsent(
      convId,
      () => AgentService(
        profile: profile,
        model: model,
        sessionId: convId,
        state: AgentState(sessionId: convId),
        memory: memory,
      ),
    );

    // 预注入本会话历史（仅最近若干条，控制上下文体积；按内容去重）
    final recent = history.length > 10
        ? history.sublist(history.length - 10)
        : history;
    final injected = _injectedHistory.putIfAbsent(convId, () => <String>{});
    for (final m in recent) {
      if (m.role == ChatRole.user && m.content.trim().isNotEmpty) {
        final t = m.content.trim();
        if (injected.contains(t)) continue;
        injected.add(t);
        agent.state.history.messages.add(UserMessage.text(t));
      }
    }

    final toolNames = <String>{};
    final sb = StringBuffer();
    try {
      await for (final ev in agent.chatStream(userText)) {
        switch (ev) {
          case AgentTextEvent():
            sb.write(ev.text);
            final idx = _messages[convId]!
                .indexWhere((m) => m.id == assistantMsgId);
            if (idx >= 0) {
              _messages[convId]![idx] =
                  _messages[convId]![idx].copyWith(content: sb.toString());
              writeThrough(convId);
            }
            notifyListeners();
          case AgentToolEvent():
            if (ev.toolName.isNotEmpty) toolNames.add(ev.toolName);
          case AgentFinishedEvent():
            final idx = _messages[convId]!
                .indexWhere((m) => m.id == assistantMsgId);
            if (idx >= 0) {
              _messages[convId]![idx] = _messages[convId]![idx].copyWith(
                content: ev.finalText.isEmpty ? '（无回复）' : ev.finalText,
                isStreaming: false,
                isError: false,
                model: model,
              );
            }
        }
      }
      // 工具摘要附加到回复末尾（轻松语气）
      if (toolNames.isNotEmpty && sb.isNotEmpty) {
        final idx = _messages[convId]!
            .indexWhere((m) => m.id == assistantMsgId);
        if (idx >= 0) {
          final content = _messages[convId]![idx].content;
          final hint = '\n\n🔧 这次用了：' + toolNames.join('、');
          if (!content.endsWith(hint)) {
            _messages[convId]![idx] =
                _messages[convId]![idx].copyWith(content: content + hint);
          }
        }
      }
      await agent.saveState();
    } catch (e) {
      _finishError(assistantMsgId, convId, 'Agent 出错了：' + e.toString());
    } finally {
      _streamed = '';
      _isGenerating = false;
      writeThrough(convId);
      _touchConversation(convId);
      notifyListeners();
    }
  }

  void _finishError(String msgId, String convId, String err) {
    final idx = _messages[convId]!.indexWhere((m) => m.id == msgId);
    if (idx >= 0) {
      _messages[convId]![idx] = _messages[convId]![idx].copyWith(
        content: err,
        isStreaming: false,
        isError: true,
      );
    }
    _isGenerating = false;
    writeThrough(convId);
    _touchConversation(convId);
    notifyListeners();
  }

  /// 停止生成
  void stopGenerating() {
    // 简单标记：置为非流式并结束（客户端层面停止接收）
    if (_isGenerating && _activeConvId != null) {
      final convId = _activeConvId!;
      final msgs = _messages[convId]!;
      final last = msgs.isNotEmpty ? msgs.last : null;
      if (last != null && last.isStreaming) {
        final content = last.content.isEmpty ? '（已停止）' : last.content;
        msgs[msgs.length - 1] = last.copyWith(
          content: content,
          isStreaming: false,
        );
        _messages[convId] = msgs;
        writeThrough(convId);
      }
      _isGenerating = false;
      _streamed = '';
      notifyListeners();
    }
  }

  /// 删除最后一条消息（重新生成）
  void regenerateLast() {
    if (_isGenerating || _activeConvId == null) return;
    final msgs = _messages[_activeConvId!]!;
    if (msgs.length >= 2 && msgs.last.role == ChatRole.assistant) {
      msgs.removeLast();
      msgs.removeLast(); // 移除对应 user 消息
      _messages[_activeConvId!] = msgs;
      writeThrough(_activeConvId!);
      notifyListeners();
    }
  }

  Future<void> clearMessages(String convId) async {
    _messages[convId] = [];
    await store.deleteMessages(convId);
    notifyListeners();
  }

  // ---------- 工具 ----------

  void writeThrough(String convId) {
    // 异步落盘，防止界面阻塞
    final snapshot = _messages[convId] ?? [];
    store.saveMessages(convId, snapshot);
  }

  void _touchConversation(String convId) {
    final i = _conversations.indexWhere((c) => c.id == convId);
    if (i >= 0) {
      _conversations[i].updatedAt = DateTime.now();
      _persistConversations();
    }
  }

  String _genId() {
    final r = Random();
    final t = DateTime.now().millisecondsSinceEpoch;
    return '$t-${r.nextInt(0xFFFF).toRadixString(16)}';
  }
}