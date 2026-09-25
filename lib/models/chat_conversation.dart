/// 聊天会话模型
class ChatConversation {
  final String id;
  String title;
  final DateTime createdAt;
  DateTime updatedAt;
  final String profileId; // 关联的 AiProfile.id
  final String model; // 会话使用的模型

  ChatConversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.profileId,
    required this.model,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'profileId': profileId,
        'model': model,
      };

  factory ChatConversation.fromJson(Map<String, dynamic> json) =>
      ChatConversation(
        id: json['id'] as String,
        title: json['title'] as String? ?? '新对话',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
            DateTime.now(),
        profileId: json['profileId'] as String? ?? '',
        model: json['model'] as String? ?? '',
      );
}

/// 聊天气泡角色
enum ChatRole { user, assistant, system }

/// 单条消息
class ChatMessage {
  final String id;
  final ChatRole role;
  final String content;
  final DateTime timestamp;
  final bool isStreaming; // 流式渲染中
  final bool isError; // 是否为错误提示
  final String? model; // 生成该消息所用模型

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.isStreaming = false,
    this.isError = false,
    this.model,
  });

  ChatMessage copyWith({
    String? id,
    ChatRole? role,
    String? content,
    DateTime? timestamp,
    bool? isStreaming,
    bool? isError,
    String? model,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
      isError: isError ?? this.isError,
      model: model ?? this.model,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role.name,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        'isStreaming': isStreaming,
        'isError': isError,
        'model': model,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String? ?? '',
        role: ChatRole.values.firstWhere(
          (r) => r.name == json['role'],
          orElse: () => ChatRole.user,
        ),
        content: json['content'] as String? ?? '',
        timestamp:
            DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
        isStreaming: json['isStreaming'] as bool? ?? false,
        isError: json['isError'] as bool? ?? false,
        model: json['model'] as String?,
      );
}