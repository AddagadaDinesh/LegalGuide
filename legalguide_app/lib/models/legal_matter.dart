import '../localization/app_strings.dart';
import '../services/locale_service.dart';

class LegalMatter {
  final int id;
  final int categoryId;
  final String name;
  final String description;
  final String nameTe;
  final String descriptionTe;
  final List<int> relatedSectionIds;

  LegalMatter({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    this.nameTe = '',
    this.descriptionTe = '',
    required this.relatedSectionIds,
  });

  bool get isAvailable => description.isNotEmpty || relatedSectionIds.isNotEmpty;

  String get displayName {
    if (LocaleService.isTelugu && nameTe.isNotEmpty) return nameTe;
    if (LocaleService.isHindi) return tr(name);
    return name;
  }

  String get displayDescription {
    if (LocaleService.isTelugu && descriptionTe.isNotEmpty) return descriptionTe;
    if (LocaleService.isHindi) return tr(description);
    return description;
  }

  factory LegalMatter.fromJson(Map<String, dynamic> json) {
    return LegalMatter(
      id: json['id'],
      categoryId: json['category'] is int
          ? json['category']
          : (json['category']?['id'] ?? 0),
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      nameTe: json['name_te'] ?? '',
      descriptionTe: json['description_te'] ?? '',
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
        'name_te': nameTe,
        'description_te': descriptionTe,
        'related_sections': relatedSectionIds,
      };
}
