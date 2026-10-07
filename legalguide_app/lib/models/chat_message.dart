class ChatMessage {
  final String id;
  final String conversationId;
  final String role; // 'user' or 'assistant'
  final String text;
  final bool isUser;
  final bool? isOnline;
  final bool requiresLogin;
  final DateTime timestamp;
  final String language;
  final String? responseMetadata;

  ChatMessage({
    String? id,
    String? conversationId,
    String? role,
    required this.text,
    required this.isUser,
    this.isOnline,
    this.requiresLogin = false,
    required this.timestamp,
    String? language,
    this.responseMetadata,
  })  : id = id ?? 'msg_${timestamp.millisecondsSinceEpoch}_${isUser ? "u" : "a"}',
        conversationId = conversationId ?? 'conv_default',
        role = role ?? (isUser ? 'user' : 'assistant'),
        language = language ?? 'en';

  String get message => text;

  Map<String, dynamic> toMap() => {
        'id': id,
        'conversation_id': conversationId,
        'role': role,
        'message': text,
        'timestamp': timestamp.toIso8601String(),
        'language': language,
        'is_user': isUser ? 1 : 0,
        'is_online': isOnline == null ? null : (isOnline! ? 1 : 0),
        'requires_login': requiresLogin ? 1 : 0,
        'response_metadata': responseMetadata,
      };

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as String?,
      conversationId: map['conversation_id'] as String?,
      role: map['role'] as String?,
      text: map['message'] as String? ?? '',
      isUser: (map['is_user'] as int? ?? 1) == 1,
      isOnline: map['is_online'] == null ? null : ((map['is_online'] as int) == 1),
      requiresLogin: (map['requires_login'] as int? ?? 0) == 1,
      timestamp: DateTime.tryParse(map['timestamp'] as String? ?? '') ?? DateTime.now(),
      language: map['language'] as String? ?? 'en',
      responseMetadata: map['response_metadata'] as String?,
    );
  }
}
