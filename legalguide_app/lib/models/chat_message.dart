class ChatMessage {
  final String text;
  final bool isUser;
  final bool? isOnline;
  final bool requiresLogin;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.isOnline,
    this.requiresLogin = false,
    required this.timestamp,
  });
}
