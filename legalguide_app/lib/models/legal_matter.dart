import '../localization/app_strings.dart';
import '../services/locale_service.dart';

class LegalMatter {
  final int id;
  final int categoryId;
  final String name;
  final String description;
  final String nameTe;
  final String descriptionTe;
  final String nameHi;
  final String descriptionHi;
  final List<int> relatedSectionIds;

  LegalMatter({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    this.nameTe = '',
    this.descriptionTe = '',
    this.nameHi = '',
    this.descriptionHi = '',
    required this.relatedSectionIds,
  });

  bool get isAvailable => description.isNotEmpty || relatedSectionIds.isNotEmpty;

  String get displayName {
    if (LocaleService.isTelugu) {
      if (nameTe.isNotEmpty) return nameTe;
      return tr(name);
    }
    if (LocaleService.isHindi) {
      if (nameHi.isNotEmpty) return nameHi;
      return tr(name);
    }
    return name;
  }

  String get displayDescription {
    if (LocaleService.isTelugu) {
      if (descriptionTe.isNotEmpty) return descriptionTe;
      return tr(description);
    }
    if (LocaleService.isHindi) {
      if (descriptionHi.isNotEmpty) return descriptionHi;
      return tr(description);
    }
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
      nameHi: json['name_hi'] ?? '',
      descriptionHi: json['description_hi'] ?? '',
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
        'name_hi': nameHi,
        'description_hi': descriptionHi,
        'related_sections': relatedSectionIds,
      };
}
