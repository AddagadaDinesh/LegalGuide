class ChatMessage {
  final String text;
  final bool isUser;
  final bool? isOnline;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.isOnline,
    required this.timestamp,
  });
}
