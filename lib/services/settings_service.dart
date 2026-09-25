import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/ai_profile.dart';

/// 应用设置持久化服务
/// 存储：AI 档案列表、当前选中的档案/模型、主题等
class SettingsService {
  static const _kProfiles = 'ai_profiles_v1';
  static const _kActiveProfileId = 'active_profile_id_v1';
  static const _kActiveModel = 'active_model_v1';
  static const _kThemeMode = 'theme_mode_v1';
  static const _kAgentEnabled = 'agent_enabled_v1';
  static const _kSearchApiKey = 'search_api_key_v1';

  List<AiProfile> _profiles = [];
  String _activeProfileId = '';
  String _activeModel = '';
  String _themeMode = 'system'; // system | light | dark
  bool _agentEnabled = false;
  String _searchApiKey = '';

  SharedPreferences? _prefs;

  List<AiProfile> get profiles => List.unmodifiable(_profiles);
  String get activeProfileId => _activeProfileId;
  String get activeModel => _activeModel;
  String get themeMode => _themeMode;
  bool get agentEnabled => _agentEnabled;
  String get searchApiKey => _searchApiKey;

  AiProfile? get activeProfile {
    if (_activeProfileId.isEmpty) return null;
    for (final p in _profiles) {
      if (p.id == _activeProfileId) return p;
    }
    return null;
  }

  /// 获取当前生效的模型名（档内默认模型兜底）
  String get effectiveModel {
    if (_activeModel.isNotEmpty) return _activeModel;
    final p = activeProfile;
    if (p?.defaultModel != null && p!.defaultModel!.isNotEmpty) {
      return p.defaultModel!;
    }
    if (p != null && p.models.isNotEmpty) return p.models.first;
    return '';
  }

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_kProfiles);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        _profiles = list
            .map((e) => AiProfile.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        _profiles = [];
      }
    }
    _activeProfileId = _prefs!.getString(_kActiveProfileId) ?? '';
    _activeModel = _prefs!.getString(_kActiveModel) ?? '';
    _themeMode = _prefs!.getString(_kThemeMode) ?? 'system';
    _agentEnabled = _prefs!.getBool(_kAgentEnabled) ?? false;
    _searchApiKey = _prefs!.getString(_kSearchApiKey) ?? '';
  }

  Future<void> saveProfiles(List<AiProfile> profiles) async {
    _profiles = [...profiles];
    await _prefs?.setString(
        _kProfiles, jsonEncode(profiles.map((e) => e.toJson()).toList()));
  }

  Future<void> saveActiveProfile(String profileId) async {
    _activeProfileId = profileId;
    await _prefs?.setString(_kActiveProfileId, profileId);
  }

  Future<void> saveActiveModel(String model) async {
    _activeModel = model;
    await _prefs?.setString(_kActiveModel, model);
  }

  Future<void> saveThemeMode(String mode) async {
    _themeMode = mode;
    await _prefs?.setString(_kThemeMode, mode);
  }

  Future<void> saveAgentEnabled(bool enabled) async {
    _agentEnabled = enabled;
    await _prefs?.setBool(_kAgentEnabled, enabled);
  }

  Future<void> saveSearchApiKey(String key) async {
    _searchApiKey = key;
    await _prefs?.setString(_kSearchApiKey, key);
  }
}