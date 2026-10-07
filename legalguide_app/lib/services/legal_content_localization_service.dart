import '../localization/app_strings.dart';
import '../models/category.dart';
import '../models/law.dart';
import '../models/legal_section.dart';
import 'locale_service.dart';

class PopularSearchItem {
  final String id;
  final String labelEn;
  final String labelTe;
  final String labelHi;
  final String queryEn;
  final String queryTe;
  final String queryHi;

  const PopularSearchItem({
    required this.id,
    required this.labelEn,
    required this.labelTe,
    required this.labelHi,
    required this.queryEn,
    required this.queryTe,
    required this.queryHi,
  });

  String get displayLabel {
    if (LocaleService.isTelugu) return labelTe;
    if (LocaleService.isHindi) return labelHi;
    return labelEn;
  }

  String get searchQuery {
    if (LocaleService.isTelugu) return queryTe;
    if (LocaleService.isHindi) return queryHi;
    return queryEn;
  }
}

class LocalizedLegalContent {
  final String title;
  final String shortName;
  final String description;
  final String simpleExplanation;
  final String purpose;
  final String punishment;
  final String relevantDocuments;
  final List<String> keyElements;
  final List<String> relevantInformation;

  const LocalizedLegalContent({
    required this.title,
    this.shortName = '',
    this.description = '',
    this.simpleExplanation = '',
    this.purpose = '',
    this.punishment = '',
    this.relevantDocuments = '',
    this.keyElements = const [],
    this.relevantInformation = const [],
  });
}

/// Centralized service for retrieving localized legal content, categories, laws, and search terms.
/// Ensures consistent presentation across widgets without ad-hoc conditional translation in views.
class LegalContentLocalizationService {
  LegalContentLocalizationService._();

  static String get currentLanguage => LocaleService.language.value;
  static bool get isEnglish => currentLanguage == 'en';
  static bool get isTelugu => LocaleService.isTelugu;
  static bool get isHindi => LocaleService.isHindi;

  static Future<void> setLanguage(String code) => LocaleService.setLanguage(code);

  static String getLocalizedText(String text) => tr(text);

  static LocalizedLegalContent getLocalizedCategory(Category category) {
    return LocalizedLegalContent(
      title: category.displayName,
      description: category.displayDescription,
    );
  }

  static LocalizedLegalContent getLocalizedLaw(Law law) {
    return LocalizedLegalContent(
      title: law.displayName,
      shortName: law.displayShortName,
      description: law.displayDescription,
    );
  }

  static LocalizedLegalContent getLocalizedSection(LegalSection section) {
    return LocalizedLegalContent(
      title: section.displayTitle,
      simpleExplanation: section.displaySimpleExplanation,
      purpose: section.displayPurpose,
      punishment: section.displayPunishment,
      relevantDocuments: section.displayRelevantDocuments,
      keyElements: section.keyElementsList,
      relevantInformation: section.relevantInformationList,
    );
  }

  /// Canonical multilingual popular searches
  static const List<PopularSearchItem> popularSearches = [
    PopularSearchItem(
      id: 'theft',
      labelEn: 'theft',
      labelTe: 'దొంగతనం',
      labelHi: 'चोरी',
      queryEn: 'theft',
      queryTe: 'దొంగతనం',
      queryHi: 'चोरी',
    ),
    PopularSearchItem(
      id: 'arrest',
      labelEn: 'arrest',
      labelTe: 'అరెస్ట్',
      labelHi: 'गिरफ्तारी',
      queryEn: 'arrest',
      queryTe: 'అరెస్ట్',
      queryHi: 'गिरफ्तारी',
    ),
    PopularSearchItem(
      id: 'cheating',
      labelEn: 'cheating',
      labelTe: 'మోసం',
      labelHi: 'धोखाधड़ी',
      queryEn: 'cheating',
      queryTe: 'మోసం',
      queryHi: 'धोखाधड़ी',
    ),
    PopularSearchItem(
      id: 'murder',
      labelEn: 'murder',
      labelTe: 'హత్య',
      labelHi: 'हत्या',
      queryEn: 'murder',
      queryTe: 'హత్య',
      queryHi: 'हत्या',
    ),
    PopularSearchItem(
      id: 'article_21',
      labelEn: 'article 21',
      labelTe: 'ఆర్టికల్ 21',
      labelHi: 'अनुच्छेद 21',
      queryEn: 'article 21',
      queryTe: 'ఆర్టికల్ 21',
      queryHi: 'अनुच्छेद 21',
    ),
  ];

  static PopularSearchItem? getLocalizedSearchTerm(String id) {
    try {
      return popularSearches.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }
}
