import '../localization/app_strings.dart';
import '../services/locale_service.dart';

class Law {
  final int id;
  final String name;
  final String shortName;
  final int categoryId;
  final String description;
  final int? year;
  final String? actNumber;
  final String? sourceUrl;
  final String sourceName;
  final String status;
  final String? lastVerified;
  final String? updatedAt;

  final String nameTe;
  final String shortNameTe;
  final String descriptionTe;
  final String nameHi;
  final String shortNameHi;
  final String descriptionHi;

  final String domain;
  final int sectionsCount;
  final int currentSectionsCount;
  final int amendedSectionsCount;
  final int historicalSectionsCount;
  final int repealedSectionsCount;

  Law({
    required this.id,
    required this.name,
    required this.shortName,
    required this.categoryId,
    required this.description,
    this.year,
    this.actNumber,
    this.sourceUrl,
    this.sourceName = 'India Code (Official Government Source)',
    this.status = 'current',
    this.lastVerified,
    this.updatedAt,
    this.nameTe = '',
    this.shortNameTe = '',
    this.descriptionTe = '',
    this.nameHi = '',
    this.shortNameHi = '',
    this.descriptionHi = '',
    this.domain = '',
    this.sectionsCount = 0,
    this.currentSectionsCount = 0,
    this.amendedSectionsCount = 0,
    this.historicalSectionsCount = 0,
    this.repealedSectionsCount = 0,
  });

  bool get isHistorical => status.toLowerCase() == 'historical' || status.toLowerCase() == 'repealed';

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

  String get displayShortName {
    if (LocaleService.isTelugu) {
      if (shortNameTe.isNotEmpty) return shortNameTe;
      return tr(shortName);
    }
    if (LocaleService.isHindi) {
      if (shortNameHi.isNotEmpty) return shortNameHi;
      return tr(shortName);
    }
    return shortName;
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

  factory Law.fromJson(Map<String, dynamic> json) {
    return Law(
      id: json['id'],
      name: json['name'] ?? '',
      shortName: json['short_name'] ?? '',
      categoryId: json['category'] is int
          ? json['category']
          : (json['category']?['id'] ?? 0),
      description: json['description'] ?? '',
      year: json['year'],
      actNumber: json['act_number'],
      sourceUrl: json['source_url'],
      sourceName: json['source_name'] ?? 'India Code (Official Government Source)',
      status: json['status'] ?? 'current',
      lastVerified: json['last_verified'],
      updatedAt: json['updated_at'],
      nameTe: json['name_te'] ?? '',
      shortNameTe: json['short_name_te'] ?? '',
      descriptionTe: json['description_te'] ?? '',
      nameHi: json['name_hi'] ?? '',
      shortNameHi: json['short_name_hi'] ?? '',
      descriptionHi: json['description_hi'] ?? '',
      domain: json['domain'] ?? json['category_name'] ?? '',
      sectionsCount: json['verified_sections_count'] as int? ?? json['sections_count'] as int? ?? 0,
      currentSectionsCount: json['current_sections_count'] as int? ?? 0,
      amendedSectionsCount: json['amended_sections_count'] as int? ?? 0,
      historicalSectionsCount: json['historical_sections_count'] as int? ?? 0,
      repealedSectionsCount: json['repealed_sections_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'short_name': shortName,
        'category': categoryId,
        'description': description,
        'year': year,
        'act_number': actNumber,
        'source_url': sourceUrl,
        'source_name': sourceName,
        'status': status,
        'last_verified': lastVerified,
        'updated_at': updatedAt,
        'name_te': nameTe,
        'short_name_te': shortNameTe,
        'description_te': descriptionTe,
        'name_hi': nameHi,
        'short_name_hi': shortNameHi,
        'description_hi': descriptionHi,
        'domain': domain,
        'sections_count': sectionsCount,
        'verified_sections_count': sectionsCount,
        'current_sections_count': currentSectionsCount,
        'amended_sections_count': amendedSectionsCount,
        'historical_sections_count': historicalSectionsCount,
        'repealed_sections_count': repealedSectionsCount,
      };
}

