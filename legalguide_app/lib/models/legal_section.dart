import '../localization/app_strings.dart';
import '../services/locale_service.dart';

class LegalSection {
  final int id;
  final int lawId;
  final String sectionNumber;
  final String title;
  final String legalText;
  final String simpleExplanation;
  final String purpose;
  final String punishment;
  final String relevantDocuments;
  final String keyElements;
  final String relevantInformation;
  final String keywords;
  final String badge;
  final String source;
  final String? lastVerified;
  final List<int> relatedSectionIds;
  final String? directActionUrl;
  final String? directActionLabel;
  final String? directActionType;

  final String titleTe;
  final String simpleExplanationTe;
  final String purposeTe;
  final String punishmentTe;
  final String keyElementsTe;
  final String relevantInformationTe;
  final String relevantDocumentsTe;

  LegalSection({
    required this.id,
    required this.lawId,
    required this.sectionNumber,
    required this.title,
    required this.legalText,
    required this.simpleExplanation,
    required this.purpose,
    required this.punishment,
    required this.relevantDocuments,
    this.keyElements = '',
    this.relevantInformation = '',
    this.keywords = '',
    this.badge = '',
    required this.source,
    this.lastVerified,
    this.relatedSectionIds = const [],
    this.directActionUrl,
    this.directActionLabel,
    this.directActionType,
    this.titleTe = '',
    this.simpleExplanationTe = '',
    this.purposeTe = '',
    this.punishmentTe = '',
    this.keyElementsTe = '',
    this.relevantInformationTe = '',
    this.relevantDocumentsTe = '',
  });

  bool get hasTeluguTranslation => titleTe.isNotEmpty;

  String get displayTitle {
    if (LocaleService.isTelugu && titleTe.isNotEmpty) return titleTe;
    if (LocaleService.isHindi) return tr(title);
    return title;
  }

  String get displaySimpleExplanation {
    if (LocaleService.isTelugu && simpleExplanationTe.isNotEmpty) return simpleExplanationTe;
    if (LocaleService.isHindi) return tr(simpleExplanation);
    return simpleExplanation;
  }

  String get displayPurpose {
    if (LocaleService.isTelugu && purposeTe.isNotEmpty) return purposeTe;
    if (LocaleService.isHindi) return tr(purpose);
    return purpose;
  }

  String get displayPunishment {
    if (LocaleService.isTelugu && punishmentTe.isNotEmpty) return punishmentTe;
    if (LocaleService.isHindi) return tr(punishment);
    return punishment;
  }

  String get displayRelevantDocuments {
    if (LocaleService.isTelugu && relevantDocumentsTe.isNotEmpty) return relevantDocumentsTe;
    if (LocaleService.isHindi) return tr(relevantDocuments);
    return relevantDocuments;
  }

  List<String> get keyElementsList {
    if (LocaleService.isTelugu && keyElementsTe.isNotEmpty) {
      return _lines(keyElementsTe);
    }
    final rawList = _lines(keyElements);
    if (LocaleService.isHindi) {
      return rawList.map((e) => tr(e)).toList();
    }
    return rawList;
  }

  List<String> get relevantInformationList {
    if (LocaleService.isTelugu && relevantInformationTe.isNotEmpty) {
      return _lines(relevantInformationTe);
    }
    final rawList = _lines(relevantInformation);
    if (LocaleService.isHindi) {
      return rawList.map((e) => tr(e)).toList();
    }
    return rawList;
  }

  static List<String> _lines(String text) => text
      .split('\n')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  factory LegalSection.fromJson(Map<String, dynamic> json) {
    return LegalSection(
      id: json['id'],
      lawId: json['law'] is int
          ? json['law']
          : (json['law']?['id'] ?? 0),
      sectionNumber: json['section_number'] ?? '',
      title: json['title'] ?? '',
      legalText: json['legal_text'] ?? '',
      simpleExplanation: json['simple_explanation'] ?? '',
      purpose: json['purpose'] ?? '',
      punishment: json['punishment'] ?? '',
      relevantDocuments: json['relevant_documents'] ?? '',
      keyElements: json['key_elements'] ?? '',
      relevantInformation: json['relevant_information'] ?? '',
      keywords: json['keywords'] ?? '',
      badge: json['badge'] ?? '',
      source: json['source'] ?? '',
      lastVerified: json['last_verified'],
      relatedSectionIds: (json['related_sections'] as List<dynamic>? ?? [])
          .map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0)
          .where((e) => e != 0)
          .toList(),
      titleTe: json['title_te'] ?? '',
      simpleExplanationTe: json['simple_explanation_te'] ?? '',
      purposeTe: json['purpose_te'] ?? '',
      punishmentTe: json['punishment_te'] ?? '',
      keyElementsTe: json['key_elements_te'] ?? '',
      relevantInformationTe: json['relevant_information_te'] ?? '',
      relevantDocumentsTe: json['relevant_documents_te'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'law': lawId,
        'section_number': sectionNumber,
        'title': title,
        'legal_text': legalText,
        'simple_explanation': simpleExplanation,
        'purpose': purpose,
        'punishment': punishment,
        'relevant_documents': relevantDocuments,
        'key_elements': keyElements,
        'relevant_information': relevantInformation,
        'keywords': keywords,
        'badge': badge,
        'source': source,
        'last_verified': lastVerified,
        'related_sections': relatedSectionIds,
        'title_te': titleTe,
        'simple_explanation_te': simpleExplanationTe,
        'purpose_te': purposeTe,
        'punishment_te': punishmentTe,
        'key_elements_te': keyElementsTe,
        'relevant_information_te': relevantInformationTe,
        'relevant_documents_te': relevantDocumentsTe,
      };
}
