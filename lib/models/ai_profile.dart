/// AI 配置档案模型
/// 描述一个 OpenAI 兼容 API 接口连接（Base URL + API Key + 模型列表）
class AiProfile {
  final String id;
  final String name;
  final String baseUrl;
  final String apiKey;
  final List<String> models;
  final String? defaultModel;
  final bool enabled;

  const AiProfile({
    required this.id,
    required this.name,
    required this.baseUrl,
    this.apiKey = '',
    this.models = const [],
    this.defaultModel,
    this.enabled = true,
  });

  AiProfile copyWith({
    String? id,
    String? name,
    String? baseUrl,
    String? apiKey,
    List<String>? models,
    String? defaultModel,
    bool? enabled,
  }) {
    return AiProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      models: models ?? this.models,
      defaultModel: defaultModel ?? this.defaultModel,
      enabled: enabled ?? this.enabled,
    );
  }

  /// 去除末尾斜杠，得到规范的 base url（如 https://api.openai.com/v1）
  String get normalizedBaseUrl {
    var u = baseUrl.trim();
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }

  /// 拼接 chat completions 地址
  String get chatEndpoint => '$normalizedBaseUrl/chat/completions';

  /// 拼接 models 列表地址
  String get modelsEndpoint => '$normalizedBaseUrl/models';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'baseUrl': baseUrl,
        'apiKey': apiKey,
        'models': models,
        'defaultModel': defaultModel,
        'enabled': enabled,
      };

  factory AiProfile.fromJson(Map<String, dynamic> json) => AiProfile(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        baseUrl: json['baseUrl'] as String? ?? '',
        apiKey: json['apiKey'] as String? ?? '',
        models: (json['models'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        defaultModel: json['defaultModel'] as String?,
        enabled: json['enabled'] as bool? ?? true,
      );
}