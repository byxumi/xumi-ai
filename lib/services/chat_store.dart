import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat_conversation.dart';

/// 聊天会话 + 消息 本地持久化
/// 所有会话存 JSON List，消息按会话 id 分文件存
class ChatStore {
  static const _kConvIndex = 'chat_conv_index_v1';
  static const _kMsgPrefix = 'chat_msgs_';

  SharedPreferences? _prefs;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ---------- 会话索引 ----------

  Future<List<ChatConversation>> loadConversations() async {
    final raw = _prefs?.getString(_kConvIndex);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => ChatConversation.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } catch (_) {
      return [];
    }
  }

  Future<void> saveConversations(List<ChatConversation> convs) async {
    await _prefs?.setString(
        _kConvIndex, jsonEncode(convs.map((e) => e.toJson()).toList()));
  }

  // ---------- 会话消息 ----------

  Future<List<ChatMessage>> loadMessages(String convId) async {
    final raw = _prefs?.getString('$_kMsgPrefix$convId');
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveMessages(String convId, List<ChatMessage> msgs) async {
    await _prefs?.setString(
        '$_kMsgPrefix$convId', jsonEncode(msgs.map((e) => e.toJson()).toList()));
  }

  Future<void> deleteMessages(String convId) async {
    await _prefs?.remove('$_kMsgPrefix$convId');
  }
}