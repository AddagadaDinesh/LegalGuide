class LegalSectionVersion {
  final int id;
  final int sectionId;
  final int version;
  final String legalText;
  final String simpleExplanation;
  final String purpose;
  final String punishment;
  final String? effectiveDate;
  final String amendmentInfo;
  final String sourceName;
  final String? sourceUrl;
  final String? archivedAt;
  final String changeSummary;

  LegalSectionVersion({
    required this.id,
    required this.sectionId,
    required this.version,
    required this.legalText,
    this.simpleExplanation = '',
    this.purpose = '',
    this.punishment = '',
    this.effectiveDate,
    this.amendmentInfo = '',
    this.sourceName = 'India Code (Official Government Source)',
    this.sourceUrl,
    this.archivedAt,
    this.changeSummary = '',
  });

  factory LegalSectionVersion.fromJson(Map<String, dynamic> json) {
    return LegalSectionVersion(
      id: json['id'] ?? 0,
      sectionId: json['section'] is int
          ? json['section']
          : (json['section']?['id'] ?? 0),
      version: json['version'] ?? 1,
      legalText: json['legal_text'] ?? '',
      simpleExplanation: json['simple_explanation'] ?? '',
      purpose: json['purpose'] ?? '',
      punishment: json['punishment'] ?? '',
      effectiveDate: json['effective_date'],
      amendmentInfo: json['amendment_info'] ?? '',
      sourceName: json['source_name'] ?? 'India Code (Official Government Source)',
      sourceUrl: json['source_url'],
      archivedAt: json['archived_at'],
      changeSummary: json['change_summary'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'section': sectionId,
        'version': version,
        'legal_text': legalText,
        'simple_explanation': simpleExplanation,
        'purpose': purpose,
        'punishment': punishment,
        'effective_date': effectiveDate,
        'amendment_info': amendmentInfo,
        'source_name': sourceName,
        'source_url': sourceUrl,
        'archived_at': archivedAt,
        'change_summary': changeSummary,
      };
}
