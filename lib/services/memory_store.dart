import 'dart:convert';
import 'dart:io';

/// 本地长期记忆：把用户偏好/事实以 key-value 存到本地 JSON 文件。
/// 供 Agent 的 remember / recall 工具使用，跨会话共享。
class MemoryStore {
  final String filePath;
  Map<String, String> _map = {};

  MemoryStore({this.filePath = 'xumi_memory.json'});

  Map<String, String> get all => Map.unmodifiable(_map);

  Future<void> init() async {
    try {
      final f = File(filePath);
      if (await f.exists()) {
        final raw = await f.readAsString();
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          _map = decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
        }
      }
    } catch (_) {
      _map = {};
    }
  }

  Future<void> _flush() async {
    try {
      await File(filePath).writeAsString(jsonEncode(_map), flush: true);
    } catch (_) {}
  }

  Future<String> remember(String key, String value) async {
    _map[key] = value;
    await _flush();
    return '已记住：' + key + ' = ' + value;
  }

  Future<String> forget(String key) async {
    _map.remove(key);
    await _flush();
    return '已忘记：' + key;
  }

  String recall(String key) => _map[key] ?? '(未找到关于 ' + key + ' 的记忆)';

  String listAll() {
    if (_map.isEmpty) return '（还没有任何记忆）';
    return _map.entries
        .map((e) => '• ' + e.key + '：' + e.value)
        .join('\n');
  }

  Future<void> clearAll() async {
    _map = {};
    await _flush();
  }
}
