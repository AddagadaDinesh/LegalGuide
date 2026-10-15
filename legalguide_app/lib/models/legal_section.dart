import 'dart:convert';
import '../localization/app_strings.dart';
import '../services/locale_service.dart';

class LegalExampleStep {
  final int order;
  final String title;
  final String description;
  final String icon;

  const LegalExampleStep({
    required this.order,
    required this.title,
    required this.description,
    this.icon = '',
  });

  factory LegalExampleStep.fromJson(Map<String, dynamic> json) {
    return LegalExampleStep(
      order: json['order'] is int
          ? json['order']
          : int.tryParse(json['order']?.toString() ?? '1') ?? 1,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      icon: json['icon']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'order': order,
        'title': title,
        'description': description,
        'icon': icon,
      };
}

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

  // Legal Database Metadata & Source Verification
  final String? effectiveDate;
  final String amendmentInfo;
  final String status;
  final String sourceName;
  final String sourceType;
  final int version;
  final String? previousVersionRef;
  final String? updatedAt;

  // Multilingual core fields
  final String titleTe;
  final String simpleExplanationTe;
  final String purposeTe;
  final String punishmentTe;
  final String keyElementsTe;
  final String relevantInformationTe;
  final String relevantDocumentsTe;

  final String titleHi;
  final String simpleExplanationHi;
  final String purposeHi;
  final String punishmentHi;
  final String keyElementsHi;
  final String relevantInformationHi;
  final String relevantDocumentsHi;

  // Universal Real-Life Example & Progressive Disclosure System
  final String quickAnswer;
  final String quickAnswerTe;
  final String quickAnswerHi;

  final String exampleTitle;
  final String exampleTitleTe;
  final String exampleTitleHi;

  final String exampleSituation;
  final String exampleSituationTe;
  final String exampleSituationHi;

  final String exampleExplanation;
  final String exampleExplanationTe;
  final String exampleExplanationHi;

  final String exampleDisclaimer;

  final String visualImageUrl;
  final String visualCaption;
  final String visualCaptionTe;
  final String visualCaptionHi;
  final String visualAltText;
  final bool isVisualIllustrative;

  final String videoUrl;
  final String videoTitle;
  final String videoDuration;
  final String videoThumbnailUrl;
  final String videoTranscript;

  final String exampleSteps; // JSON string of List<LegalExampleStep>

  final String whatYouShouldDo;
  final String whatYouShouldDoTe;
  final String whatYouShouldDoHi;

  final String consequencesType; // 'penal', 'civil', 'order', 'fine', 'procedural'

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
    this.effectiveDate,
    this.amendmentInfo = '',
    this.status = 'current',
    this.sourceName = 'India Code (Official Government Source)',
    this.sourceType = 'Official Bare Act Gazette',
    this.version = 1,
    this.previousVersionRef,
    this.updatedAt,
    this.titleTe = '',
    this.simpleExplanationTe = '',
    this.purposeTe = '',
    this.punishmentTe = '',
    this.keyElementsTe = '',
    this.relevantInformationTe = '',
    this.relevantDocumentsTe = '',
    this.titleHi = '',
    this.simpleExplanationHi = '',
    this.purposeHi = '',
    this.punishmentHi = '',
    this.keyElementsHi = '',
    this.relevantInformationHi = '',
    this.relevantDocumentsHi = '',
    this.quickAnswer = '',
    this.quickAnswerTe = '',
    this.quickAnswerHi = '',
    this.exampleTitle = '',
    this.exampleTitleTe = '',
    this.exampleTitleHi = '',
    this.exampleSituation = '',
    this.exampleSituationTe = '',
    this.exampleSituationHi = '',
    this.exampleExplanation = '',
    this.exampleExplanationTe = '',
    this.exampleExplanationHi = '',
    this.exampleDisclaimer = '',
    this.visualImageUrl = '',
    this.visualCaption = '',
    this.visualCaptionTe = '',
    this.visualCaptionHi = '',
    this.visualAltText = '',
    this.isVisualIllustrative = true,
    this.videoUrl = '',
    this.videoTitle = '',
    this.videoDuration = '',
    this.videoThumbnailUrl = '',
    this.videoTranscript = '',
    this.exampleSteps = '',
    this.whatYouShouldDo = '',
    this.whatYouShouldDoTe = '',
    this.whatYouShouldDoHi = '',
    this.consequencesType = 'penal',
  });

  bool get hasTeluguTranslation => titleTe.isNotEmpty;
  bool get isHistorical => status.toLowerCase() == 'historical';
  bool get isRepealed => status.toLowerCase() == 'repealed';
  bool get isAmended => status.toLowerCase() == 'amended';
  bool get isCurrent => status.toLowerCase() == 'current';

  static String normalizeSectionNumber(String raw) {
    if (raw.trim().isEmpty) return '';
    var s = raw.trim();
    // Normalize spaces around parentheses: "103 (1)" -> "103(1)"
    s = s.replaceAll(RegExp(r'\s*\(\s*'), '(');
    s = s.replaceAll(RegExp(r'\s*\)\s*'), ')');
    // If it starts with "bnss section", "bns section", convert to "section"
    s = s.replaceFirst(RegExp(r'^(bns|bnss|bsa|crpc|ipc)\s+section\b', caseSensitive: false), 'section');
    return s;
  }

  static int canonicalLawId(int lawId, [String lawName = '', String lawShortName = '']) {
    final nameLower = '$lawName $lawShortName'.toLowerCase().trim();
    if (nameLower.isNotEmpty) {
      if (nameLower.contains('nyaya') || nameLower.contains('bns')) return 2;
      if (nameLower.contains('constitution') || nameLower.contains('coi')) return 3;
      if (nameLower.contains('arrest') || nameLower.contains('rights')) return 4;
      if (nameLower.contains('technology') || nameLower.contains('it act')) return 5;
      if (nameLower.contains('motor') || nameLower.contains('mv act')) return 6;
      if (nameLower.contains('consumer') || nameLower.contains('cpa')) return 7;
      if (nameLower.contains('hindu marriage') || nameLower.contains('hma')) return 8;
      if (nameLower.contains('domestic violence') || nameLower.contains('dv act')) return 9;
      if (nameLower.contains('nagarik') || nameLower.contains('bnss')) return 10;
      if (nameLower.contains('property') || nameLower.contains('tpa')) return 11;
      if (nameLower.contains('registration')) return 12;
      if (nameLower.contains('posh') || nameLower.contains('workplace')) return 13;
      if (nameLower.contains('dowry')) return 14;
      if (nameLower.contains('pocso') || nameLower.contains('children')) return 15;
      if (nameLower.contains('social security') || nameLower.contains('css')) return 16;
      if (nameLower.contains('industrial relations') || nameLower.contains('ir code')) return 17;
    }
    return lawId;
  }

  static String computeProvisionKey(int lawId, String sectionNumber, {String lawName = '', String lawShortName = ''}) {
    final canonLaw = canonicalLawId(lawId, lawName, lawShortName);
    final normSec = normalizeSectionNumber(sectionNumber);
    final cleanSec = normSec
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return '${canonLaw}_$cleanSec';
  }

  String get provisionKey => computeProvisionKey(lawId, sectionNumber, lawName: lawName, lawShortName: lawShortName);

  bool get hasRealLifeExample =>
      displayExampleSituation.trim().isNotEmpty ||
      displayExampleExplanation.trim().isNotEmpty ||
      exampleSituation.trim().isNotEmpty ||
      exampleExplanation.trim().isNotEmpty;
  bool get hasVisualExample => visualImageUrl.trim().isNotEmpty;
  bool get hasVideoExample => videoUrl.trim().isNotEmpty;
  bool get hasSteps => exampleStepsList.isNotEmpty;


  bool get isVerifiedStatutoryText =>
      legalText.trim().isNotEmpty &&
      !legalText.trim().toLowerCase().startsWith('summary:') &&
      (sourceType.toLowerCase().contains('official') ||
          sourceType.toLowerCase().contains('bare act') ||
          source.contains('indiacode'));

  String get lawShortName {
    switch (lawId) {
      case 2:
        return 'BNS 2023';
      case 3:
        return 'COI 1950';
      case 4:
        return 'Rights';
      case 5:
        return 'IT Act';
      case 6:
        return 'MV Act';
      case 7:
        return 'CPA';
      case 8:
        return 'HMA 1955';
      case 9:
        return 'DV Act 2005';
      case 10:
        return 'BNSS-Maintenance';
      case 11:
        return 'TPA 1882';
      case 12:
        return 'Registration Act 1908';
      case 13:
        return 'POSH Act 2013';
      case 14:
        return 'Dowry Act 1961';
      case 15:
        return 'POCSO 2012';
      case 16:
        return 'CSS 2020';
      case 17:
        return 'IR Code 2020';
      default:
        return '';
    }
  }

  String get lawName {
    switch (lawId) {
      case 2:
        return 'Bharatiya Nyaya Sanhita, 2023';
      case 3:
        return 'Constitution of India';
      case 4:
        return 'Arrest & Detention Rights';
      case 5:
        return 'Information Technology Act, 2000';
      case 6:
        return 'Motor Vehicles Act, 1988 (as amended 2019)';
      case 7:
        return 'Consumer Protection Act, 2019';
      case 8:
        return 'Hindu Marriage Act, 1955';
      case 9:
        return 'Protection of Women from Domestic Violence Act, 2005';
      case 10:
        return 'Bharatiya Nagarik Suraksha Sanhita, 2023';
      case 11:
        return 'Transfer of Property Act, 1882';
      case 12:
        return 'Registration Act, 1908';
      case 13:
        return 'POSH Act, 2013';
      case 14:
        return 'Dowry Prohibition Act, 1961';
      case 15:
        return 'POCSO Act, 2012';
      case 16:
        return 'Code on Social Security, 2020';
      case 17:
        return 'Industrial Relations Code, 2020';
      default:
        return sourceName.isNotEmpty ? sourceName : 'Indian Law';
    }
  }

  String get statusDisplayLabel {
    switch (status.toLowerCase()) {
      case 'historical':
        return tr('Historical / Former Provision');
      case 'repealed':
        return tr('Repealed Provision');
      case 'amended':
        return tr('Amended Provision');
      case 'current':
      default:
        return tr('Current Law');
    }
  }

  String get versionLabel => 'LegalGuide Version: v$version';

  String get displayTitle {
    if (LocaleService.isTelugu) {
      if (titleTe.isNotEmpty) return titleTe;
      return tr(title);
    }
    if (LocaleService.isHindi) {
      if (titleHi.isNotEmpty) return titleHi;
      return tr(title);
    }
    return title;
  }

  String get displaySimpleExplanation {
    if (LocaleService.isTelugu) {
      if (simpleExplanationTe.isNotEmpty) return simpleExplanationTe;
      return tr(simpleExplanation);
    }
    if (LocaleService.isHindi) {
      if (simpleExplanationHi.isNotEmpty) return simpleExplanationHi;
      return tr(simpleExplanation);
    }
    return simpleExplanation;
  }

  String get displayQuickAnswer {
    if (LocaleService.isTelugu) {
      if (quickAnswerTe.isNotEmpty) return quickAnswerTe;
    } else if (LocaleService.isHindi) {
      if (quickAnswerHi.isNotEmpty) return quickAnswerHi;
    }
    if (quickAnswer.isNotEmpty) return quickAnswer;
    // Fallback cleanly to simpleExplanation if quickAnswer not explicitly provided
    return displaySimpleExplanation;
  }

  String get displayExampleTitle {
    if (LocaleService.isTelugu && exampleTitleTe.isNotEmpty) return exampleTitleTe;
    if (LocaleService.isHindi && exampleTitleHi.isNotEmpty) return exampleTitleHi;
    if (exampleTitle.isNotEmpty) return exampleTitle;
    return tr('Realistic Educational Scenario');
  }

  String get displayExampleSituation {
    if (LocaleService.isTelugu && exampleSituationTe.isNotEmpty) return exampleSituationTe;
    if (LocaleService.isHindi && exampleSituationHi.isNotEmpty) return exampleSituationHi;
    return exampleSituation;
  }

  String get displayExampleExplanation {
    if (LocaleService.isTelugu && exampleExplanationTe.isNotEmpty) return exampleExplanationTe;
    if (LocaleService.isHindi && exampleExplanationHi.isNotEmpty) return exampleExplanationHi;
    return exampleExplanation;
  }

  String get displayExampleDisclaimer {
    if (exampleDisclaimer.isNotEmpty) return tr(exampleDisclaimer);
    return tr('Fictional educational example. This scenario is provided only to help explain the legal concept and does not represent an actual case.');
  }

  String get displayVisualCaption {
    if (LocaleService.isTelugu && visualCaptionTe.isNotEmpty) return visualCaptionTe;
    if (LocaleService.isHindi && visualCaptionHi.isNotEmpty) return visualCaptionHi;
    return visualCaption;
  }

  // Model-level getters for visual and example media
  String get exampleImageUrl => visualImageUrl;
  String get exampleImageThumbnail => videoThumbnailUrl.isNotEmpty ? videoThumbnailUrl : visualImageUrl;
  String get exampleImageCaption => visualCaption;
  String get exampleImageAltText => visualAltText;
  bool get exampleImageEnabled => isVisualIllustrative && visualImageUrl.trim().isNotEmpty;

  String get displayPurpose {
    if (LocaleService.isTelugu) {
      if (purposeTe.isNotEmpty) return purposeTe;
      return tr(purpose);
    }
    if (LocaleService.isHindi) {
      if (purposeHi.isNotEmpty) return purposeHi;
      return tr(purpose);
    }
    return purpose;
  }

  String get displayPunishment {
    if (LocaleService.isTelugu) {
      if (punishmentTe.isNotEmpty) return punishmentTe;
      return tr(punishment);
    }
    if (LocaleService.isHindi) {
      if (punishmentHi.isNotEmpty) return punishmentHi;
      return tr(punishment);
    }
    return punishment;
  }

  String get displayRelevantDocuments {
    if (LocaleService.isTelugu) {
      if (relevantDocumentsTe.isNotEmpty) return relevantDocumentsTe;
      return tr(relevantDocuments);
    }
    if (LocaleService.isHindi) {
      if (relevantDocumentsHi.isNotEmpty) return relevantDocumentsHi;
      return tr(relevantDocuments);
    }
    return relevantDocuments;
  }

  String get displayWhatYouShouldDo {
    if (LocaleService.isTelugu && whatYouShouldDoTe.isNotEmpty) return whatYouShouldDoTe;
    if (LocaleService.isHindi && whatYouShouldDoHi.isNotEmpty) return whatYouShouldDoHi;
    return whatYouShouldDo;
  }

  List<String> get whatYouShouldDoList {
    final text = displayWhatYouShouldDo;
    if (text.isEmpty) return [];
    return _lines(text);
  }

  String get consequencesHeaderTitle {
    switch (consequencesType.toLowerCase()) {
      case 'order':
        return tr('Court Orders & Enforcement');
      case 'civil':
        return tr('Civil Consequences & Remedies');
      case 'fine':
        return tr('Statutory Penalties & Fines');
      case 'procedural':
        return tr('Procedural Consequences');
      case 'penal':
      default:
        return tr('Punishment & Penalties');
    }
  }

  String get documentsHeaderTitle => tr('Documents That May Be Relevant');

  List<LegalExampleStep> get exampleStepsList {
    if (exampleSteps.trim().isEmpty) return [];
    try {
      final decoded = jsonDecode(exampleSteps);
      if (decoded is List) {
        return decoded
            .map((item) => LegalExampleStep.fromJson(item as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));
      }
    } catch (_) {}
    return [];
  }

  List<String> get keyElementsList {
    if (LocaleService.isTelugu && keyElementsTe.isNotEmpty) {
      return _lines(keyElementsTe);
    }
    if (LocaleService.isHindi && keyElementsHi.isNotEmpty) {
      return _lines(keyElementsHi);
    }
    final rawList = _lines(keyElements);
    if (LocaleService.isHindi || LocaleService.isTelugu) {
      return rawList.map((e) => tr(e)).toList();
    }
    return rawList;
  }

  List<String> get relevantInformationList {
    if (LocaleService.isTelugu && relevantInformationTe.isNotEmpty) {
      return _lines(relevantInformationTe);
    }
    if (LocaleService.isHindi && relevantInformationHi.isNotEmpty) {
      return _lines(relevantInformationHi);
    }
    final rawList = _lines(relevantInformation);
    if (LocaleService.isHindi || LocaleService.isTelugu) {
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
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      lawId: json['law'] is int
          ? json['law']
          : (json['law']?['id'] ?? json['law_id'] ?? 0),
      sectionNumber: json['section_number']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      legalText: json['legal_text']?.toString() ?? '',
      simpleExplanation: json['simple_explanation']?.toString() ?? '',
      purpose: json['purpose']?.toString() ?? '',
      punishment: json['punishment']?.toString() ?? '',
      relevantDocuments: json['relevant_documents']?.toString() ?? '',
      keyElements: json['key_elements']?.toString() ?? '',
      relevantInformation: json['relevant_information']?.toString() ?? '',
      keywords: json['keywords']?.toString() ?? '',
      badge: json['badge']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
      lastVerified: json['last_verified']?.toString(),
      relatedSectionIds: (json['related_sections'] as List<dynamic>? ?? [])
          .map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0)
          .where((e) => e != 0)
          .toList(),
      directActionUrl: json['direct_action_url']?.toString(),
      directActionLabel: json['direct_action_label']?.toString(),
      directActionType: json['direct_action_type']?.toString(),
      effectiveDate: json['effective_date']?.toString(),
      amendmentInfo: json['amendment_info']?.toString() ?? '',
      status: json['status']?.toString() ?? 'current',
      sourceName: json['source_name']?.toString() ?? 'India Code (Official Government Source)',
      sourceType: json['source_type']?.toString() ?? 'Official Bare Act Gazette',
      version: json['version'] is int ? json['version'] : int.tryParse(json['version']?.toString() ?? '1') ?? 1,
      previousVersionRef: json['previous_version_ref']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      titleTe: json['title_te']?.toString() ?? '',
      simpleExplanationTe: json['simple_explanation_te']?.toString() ?? '',
      purposeTe: json['purpose_te']?.toString() ?? '',
      punishmentTe: json['punishment_te']?.toString() ?? '',
      keyElementsTe: json['key_elements_te']?.toString() ?? '',
      relevantInformationTe: json['relevant_information_te']?.toString() ?? '',
      relevantDocumentsTe: json['relevant_documents_te']?.toString() ?? '',
      titleHi: json['title_hi']?.toString() ?? '',
      simpleExplanationHi: json['simple_explanation_hi']?.toString() ?? '',
      purposeHi: json['purpose_hi']?.toString() ?? '',
      punishmentHi: json['punishment_hi']?.toString() ?? '',
      keyElementsHi: json['key_elements_hi']?.toString() ?? '',
      relevantInformationHi: json['relevant_information_hi']?.toString() ?? '',
      relevantDocumentsHi: json['relevant_documents_hi']?.toString() ?? '',
      quickAnswer: json['quick_answer']?.toString() ?? '',
      quickAnswerTe: json['quick_answer_te']?.toString() ?? '',
      quickAnswerHi: json['quick_answer_hi']?.toString() ?? '',
      exampleTitle: json['example_title']?.toString() ?? '',
      exampleTitleTe: json['example_title_te']?.toString() ?? '',
      exampleTitleHi: json['example_title_hi']?.toString() ?? '',
      exampleSituation: json['example_situation']?.toString() ?? '',
      exampleSituationTe: json['example_situation_te']?.toString() ?? '',
      exampleSituationHi: json['example_situation_hi']?.toString() ?? '',
      exampleExplanation: json['example_explanation']?.toString() ?? '',
      exampleExplanationTe: json['example_explanation_te']?.toString() ?? '',
      exampleExplanationHi: json['example_explanation_hi']?.toString() ?? '',
      exampleDisclaimer: json['example_disclaimer']?.toString() ?? '',
      visualImageUrl: json['visual_image_url']?.toString() ?? '',
      visualCaption: json['visual_caption']?.toString() ?? '',
      visualCaptionTe: json['visual_caption_te']?.toString() ?? '',
      visualCaptionHi: json['visual_caption_hi']?.toString() ?? '',
      visualAltText: json['visual_alt_text']?.toString() ?? '',
      isVisualIllustrative: json['is_visual_illustrative'] == true ||
          json['is_visual_illustrative'] == 1 ||
          json['is_visual_illustrative'] == '1' ||
          json['is_visual_illustrative'] == null,
      videoUrl: json['video_url']?.toString() ?? '',
      videoTitle: json['video_title']?.toString() ?? '',
      videoDuration: json['video_duration']?.toString() ?? '',
      videoThumbnailUrl: json['video_thumbnail_url']?.toString() ?? '',
      videoTranscript: json['video_transcript']?.toString() ?? '',
      exampleSteps: json['example_steps'] is String
          ? json['example_steps']
          : (json['example_steps'] != null ? jsonEncode(json['example_steps']) : ''),
      whatYouShouldDo: json['what_you_should_do']?.toString() ?? '',
      whatYouShouldDoTe: json['what_you_should_do_te']?.toString() ?? '',
      whatYouShouldDoHi: json['what_you_should_do_hi']?.toString() ?? '',
      consequencesType: json['consequences_type']?.toString() ?? 'penal',
    );
  }

  LegalSection copyWith({
    String? visualImageUrl,
    String? visualCaption,
    String? visualAltText,
    bool? isVisualIllustrative,
    String? exampleSituation,
    String? exampleExplanation,
    String? exampleDisclaimer,
  }) {
    return LegalSection(
      id: id,
      lawId: lawId,
      sectionNumber: sectionNumber,
      title: title,
      legalText: legalText,
      simpleExplanation: simpleExplanation,
      purpose: purpose,
      punishment: punishment,
      relevantDocuments: relevantDocuments,
      keyElements: keyElements,
      relevantInformation: relevantInformation,
      keywords: keywords,
      badge: badge,
      source: source,
      lastVerified: lastVerified,
      relatedSectionIds: relatedSectionIds,
      directActionUrl: directActionUrl,
      directActionLabel: directActionLabel,
      directActionType: directActionType,
      effectiveDate: effectiveDate,
      amendmentInfo: amendmentInfo,
      status: status,
      sourceName: sourceName,
      sourceType: sourceType,
      version: version,
      previousVersionRef: previousVersionRef,
      updatedAt: updatedAt,
      titleTe: titleTe,
      simpleExplanationTe: simpleExplanationTe,
      purposeTe: purposeTe,
      punishmentTe: punishmentTe,
      keyElementsTe: keyElementsTe,
      relevantInformationTe: relevantInformationTe,
      relevantDocumentsTe: relevantDocumentsTe,
      titleHi: titleHi,
      simpleExplanationHi: simpleExplanationHi,
      purposeHi: purposeHi,
      punishmentHi: punishmentHi,
      keyElementsHi: keyElementsHi,
      relevantInformationHi: relevantInformationHi,
      relevantDocumentsHi: relevantDocumentsHi,
      quickAnswer: quickAnswer,
      quickAnswerTe: quickAnswerTe,
      quickAnswerHi: quickAnswerHi,
      exampleTitle: exampleTitle,
      exampleTitleTe: exampleTitleTe,
      exampleTitleHi: exampleTitleHi,
      exampleSituation: exampleSituation ?? this.exampleSituation,
      exampleSituationTe: exampleSituationTe,
      exampleSituationHi: exampleSituationHi,
      exampleExplanation: exampleExplanation ?? this.exampleExplanation,
      exampleExplanationTe: exampleExplanationTe,
      exampleExplanationHi: exampleExplanationHi,
      exampleDisclaimer: exampleDisclaimer ?? this.exampleDisclaimer,
      visualImageUrl: visualImageUrl ?? this.visualImageUrl,
      visualCaption: visualCaption ?? this.visualCaption,
      visualCaptionTe: visualCaptionTe,
      visualCaptionHi: visualCaptionHi,
      visualAltText: visualAltText ?? this.visualAltText,
      isVisualIllustrative: isVisualIllustrative ?? this.isVisualIllustrative,
      videoUrl: videoUrl,
      videoTitle: videoTitle,
      videoDuration: videoDuration,
      videoThumbnailUrl: videoThumbnailUrl,
      videoTranscript: videoTranscript,
      exampleSteps: exampleSteps,
      whatYouShouldDo: whatYouShouldDo,
      whatYouShouldDoTe: whatYouShouldDoTe,
      whatYouShouldDoHi: whatYouShouldDoHi,
      consequencesType: consequencesType,
    );
  }

  Map<String, dynamic> toJson() => {

        'id': id,
        'law': lawId,
        'section_number': sectionNumber,
        'provision_key': provisionKey,
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
        'direct_action_url': directActionUrl,
        'direct_action_label': directActionLabel,
        'direct_action_type': directActionType,
        'effective_date': effectiveDate,
        'amendment_info': amendmentInfo,
        'status': status,
        'source_name': sourceName,
        'source_type': sourceType,
        'version': version,
        'previous_version_ref': previousVersionRef,
        'updated_at': updatedAt,
        'title_te': titleTe,
        'simple_explanation_te': simpleExplanationTe,
        'purpose_te': purposeTe,
        'punishment_te': punishmentTe,
        'key_elements_te': keyElementsTe,
        'relevant_information_te': relevantInformationTe,
        'relevant_documents_te': relevantDocumentsTe,
        'title_hi': titleHi,
        'simple_explanation_hi': simpleExplanationHi,
        'purpose_hi': purposeHi,
        'punishment_hi': punishmentHi,
        'key_elements_hi': keyElementsHi,
        'relevant_information_hi': relevantInformationHi,
        'relevant_documents_hi': relevantDocumentsHi,
        'quick_answer': quickAnswer,
        'quick_answer_te': quickAnswerTe,
        'quick_answer_hi': quickAnswerHi,
        'example_title': exampleTitle,
        'example_title_te': exampleTitleTe,
        'example_title_hi': exampleTitleHi,
        'example_situation': exampleSituation,
        'example_situation_te': exampleSituationTe,
        'example_situation_hi': exampleSituationHi,
        'example_explanation': exampleExplanation,
        'example_explanation_te': exampleExplanationTe,
        'example_explanation_hi': exampleExplanationHi,
        'example_disclaimer': exampleDisclaimer,
        'visual_image_url': visualImageUrl,
        'visual_caption': visualCaption,
        'visual_caption_te': visualCaptionTe,
        'visual_caption_hi': visualCaptionHi,
        'visual_alt_text': visualAltText,
        'is_visual_illustrative': isVisualIllustrative ? 1 : 0,
        'video_url': videoUrl,
        'video_title': videoTitle,
        'video_duration': videoDuration,
        'video_thumbnail_url': videoThumbnailUrl,
        'video_transcript': videoTranscript,
        'example_steps': exampleSteps,
        'what_you_should_do': whatYouShouldDo,
        'what_you_should_do_te': whatYouShouldDoTe,
        'what_you_should_do_hi': whatYouShouldDoHi,
        'consequences_type': consequencesType,
      };
}
