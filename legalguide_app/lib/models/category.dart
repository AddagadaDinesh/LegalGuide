import '../localization/app_strings.dart';
import '../services/locale_service.dart';

class Category {
  final int id;
  final String name;
  final String description;
  final String nameTe;
  final String descriptionTe;
  final String nameHi;
  final String descriptionHi;

  Category({
    required this.id,
    required this.name,
    required this.description,
    this.nameTe = '',
    this.descriptionTe = '',
    this.nameHi = '',
    this.descriptionHi = '',
  });

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

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      nameTe: json['name_te'] ?? '',
      descriptionTe: json['description_te'] ?? '',
      nameHi: json['name_hi'] ?? '',
      descriptionHi: json['description_hi'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'name_te': nameTe,
        'description_te': descriptionTe,
        'name_hi': nameHi,
        'description_hi': descriptionHi,
      };
}
