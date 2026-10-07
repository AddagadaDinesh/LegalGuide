class Conversation {
  final String id;
  String title;
  final DateTime createdAt;
  DateTime updatedAt;
  final String language;
  bool isActive;

  Conversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.language,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'language': language,
        'is_active': isActive ? 1 : 0,
      };

  factory Conversation.fromMap(Map<String, dynamic> map) {
    return Conversation(
      id: map['id'] as String,
      title: map['title'] as String? ?? 'Conversation',
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ?? DateTime.now(),
      language: map['language'] as String? ?? 'en',
      isActive: (map['is_active'] as int? ?? 1) == 1,
    );
  }
}
