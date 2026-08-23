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
  });

  List<String> get keyElementsList => keyElements
      .split('\n')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  List<String> get relevantInformationList => relevantInformation
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
      };
}
