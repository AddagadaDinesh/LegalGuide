import '../services/locale_service.dart';

class Category {
  final int id;
  final String name;
  final String description;
  final String nameTe;
  final String descriptionTe;

  Category({
    required this.id,
    required this.name,
    required this.description,
    this.nameTe = '',
    this.descriptionTe = '',
  });

  String get displayName => LocaleService.isTelugu && nameTe.isNotEmpty ? nameTe : name;
  String get displayDescription =>
      LocaleService.isTelugu && descriptionTe.isNotEmpty ? descriptionTe : description;

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      nameTe: json['name_te'] ?? '',
      descriptionTe: json['description_te'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'name_te': nameTe,
        'description_te': descriptionTe,
      };
}
