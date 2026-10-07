/// A user-visible legal update record.
/// Only PUBLISHED / admin-approved updates are visible here.
/// Internal admin terminology is never exposed.
class LegalUpdate {
  final int id;
  final String title;
  final String description;
  final String updateType; // 'amendment', 'new_section', 'repeal', 'rule_change', 'penalty_change', 'new_act'
  final String updateTypeDisplay;
  final String affectedLawName;
  final String affectedLawShortName;
  final String affectedSection;
  final int? oldVersion;
  final int? newVersion;
  final String officialSourceName;
  final String officialSourceUrl;
  final String? effectiveDate;
  final String publishedAt;
  final String? lastVerifiedAt;

  /// Local-only: whether the user has read this update
  bool isRead;

  LegalUpdate({
    required this.id,
    required this.title,
    required this.description,
    required this.updateType,
    required this.updateTypeDisplay,
    required this.affectedLawName,
    required this.affectedLawShortName,
    required this.affectedSection,
    this.oldVersion,
    this.newVersion,
    required this.officialSourceName,
    required this.officialSourceUrl,
    this.effectiveDate,
    required this.publishedAt,
    this.lastVerifiedAt,
    this.isRead = false,
  });

  factory LegalUpdate.fromJson(Map<String, dynamic> json) {
    return LegalUpdate(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      updateType: json['update_type'] as String? ?? 'amendment',
      updateTypeDisplay: json['update_type_display'] as String? ?? 'Amendment',
      affectedLawName: json['affected_law_name'] as String? ?? '',
      affectedLawShortName: json['affected_law_short_name'] as String? ?? '',
      affectedSection: json['affected_section'] as String? ?? '',
      oldVersion: json['old_version'] as int?,
      newVersion: json['new_version'] as int?,
      officialSourceName:
          json['official_source_name'] as String? ?? 'Official Government Source',
      officialSourceUrl:
          json['official_source_url'] as String? ?? 'https://www.indiacode.gov.in/',
      effectiveDate: json['effective_date'] as String?,
      publishedAt: json['published_at'] as String? ?? DateTime.now().toIso8601String(),
      lastVerifiedAt: json['last_verified_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'update_type': updateType,
        'update_type_display': updateTypeDisplay,
        'affected_law_name': affectedLawName,
        'affected_law_short_name': affectedLawShortName,
        'affected_section': affectedSection,
        'old_version': oldVersion,
        'new_version': newVersion,
        'official_source_name': officialSourceName,
        'official_source_url': officialSourceUrl,
        'effective_date': effectiveDate,
        'published_at': publishedAt,
        'last_verified_at': lastVerifiedAt,
      };

  /// Returns a friendly date string from the publishedAt ISO timestamp.
  String get formattedPublishedDate {
    try {
      final dt = DateTime.parse(publishedAt).toLocal();
      final months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${dt.day} ${months[dt.month]} ${dt.year}';
    } catch (_) {
      return publishedAt;
    }
  }

  String get formattedEffectiveDate {
    if (effectiveDate == null || effectiveDate!.isEmpty) return '';
    try {
      final dt = DateTime.parse(effectiveDate!);
      final months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${dt.day} ${months[dt.month]} ${dt.year}';
    } catch (_) {
      return effectiveDate!;
    }
  }
}
