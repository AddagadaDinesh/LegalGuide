class LegalMatter {
  final int id;
  final int categoryId;
  final String name;
  final String description;
  final List<int> relatedSectionIds;

  LegalMatter({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.relatedSectionIds,
  });

  bool get isAvailable => description.isNotEmpty || relatedSectionIds.isNotEmpty;

  factory LegalMatter.fromJson(Map<String, dynamic> json) {
    return LegalMatter(
      id: json['id'],
      categoryId: json['category'] is int
          ? json['category']
          : (json['category']?['id'] ?? 0),
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      relatedSectionIds: (json['related_sections'] as List<dynamic>? ?? [])
          .map((e) => e as int)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': categoryId,
        'name': name,
        'description': description,
        'related_sections': relatedSectionIds,
      };
}
