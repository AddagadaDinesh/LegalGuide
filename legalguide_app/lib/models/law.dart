class Law {
  final int id;
  final String name;
  final String shortName;
  final int categoryId;
  final String description;

  Law({
    required this.id,
    required this.name,
    required this.shortName,
    required this.categoryId,
    required this.description,
  });

  factory Law.fromJson(Map<String, dynamic> json) {
    return Law(
      id: json['id'],
      name: json['name'] ?? '',
      shortName: json['short_name'] ?? '',
      categoryId: json['category'] is int
          ? json['category']
          : (json['category']?['id'] ?? 0),
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'short_name': shortName,
        'category': categoryId,
        'description': description,
      };
}
