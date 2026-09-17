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
    this.titleTe = '',
    this.simpleExplanationTe = '',
    this.purposeTe = '',
    this.punishmentTe = '',
    this.keyElementsTe = '',
    this.relevantInformationTe = '',
    this.relevantDocumentsTe = '',
  });

  bool get hasTeluguTranslation => titleTe.isNotEmpty;

  String get displayTitle => LocaleService.isTelugu && titleTe.isNotEmpty ? titleTe : title;
  String get displaySimpleExplanation =>
      LocaleService.isTelugu && simpleExplanationTe.isNotEmpty ? simpleExplanationTe : simpleExplanation;
  String get displayPurpose =>
      LocaleService.isTelugu && purposeTe.isNotEmpty ? purposeTe : purpose;
  String get displayPunishment =>
      LocaleService.isTelugu && punishmentTe.isNotEmpty ? punishmentTe : punishment;
  String get displayRelevantDocuments =>
      LocaleService.isTelugu && relevantDocumentsTe.isNotEmpty ? relevantDocumentsTe : relevantDocuments;

  List<String> get keyElementsList => _lines(
      LocaleService.isTelugu && keyElementsTe.isNotEmpty ? keyElementsTe : keyElements);

  List<String> get relevantInformationList => _lines(
      LocaleService.isTelugu && relevantInformationTe.isNotEmpty
          ? relevantInformationTe
          : relevantInformation);

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
