import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../localization/app_strings.dart';
import '../models/legal_section.dart';
import '../models/legal_section_version.dart';
import '../repositories/legal_data_repository.dart';
import '../services/analytics_service.dart';
import '../services/bookmark_service.dart';
import '../services/locale_service.dart';
import '../services/sqlite_legal_db.dart';
import '../services/tts_service.dart';
import '../services/view_count_service.dart';
import '../theme/app_theme.dart';
import '../utils/section_lookup.dart';

typedef LegalDetailScreen = SectionDetailScreen;

class SectionDetailScreen extends StatefulWidget {
  final LegalSection? section;
  final int? sectionId;

  const SectionDetailScreen({
    super.key,
    this.section,
    this.sectionId,
  }) : assert(section != null || sectionId != null, 'Either section or sectionId must be provided');

  @override
  State<SectionDetailScreen> createState() => _SectionDetailScreenState();
}

class _SectionDetailScreenState extends State<SectionDetailScreen> {
  LegalSection? _section;
  bool _isLoading = true;
  bool _isBookmarked = false;
  List<LegalSection> _relatedSections = [];
  List<LegalSectionVersion> _versions = [];
  bool _showVersionHistory = false;
  CategoryStyle _style = categoryStyleFor('');

  // Progressive disclosure accordions state
  bool _keyElementsExpanded = false;
  bool _documentsExpanded = false;
  bool _consequencesExpanded = false;
  bool _relatedLawsExpanded = false;
  bool _statutoryTextExpanded = false;

  LegalSection get section => _section!;

  @override
  void initState() {
    super.initState();
    _initSection();
  }

  Future<void> _initSection() async {
    if (widget.section != null) {
      _section = widget.section;
      _isLoading = false;
      _postInit();
    } else if (widget.sectionId != null) {
      final loaded = await SqliteLegalDb.getSectionById(widget.sectionId!);
      if (!mounted) return;
      setState(() {
        _section = loaded;
        _isLoading = false;
      });
      if (_section != null) _postInit();
    }
  }

  void _postInit() {
    final s = _section!;
    ViewCountService.recordView(s.id);
    AnalyticsService.trackSectionView(s.id, s.title, lawName: s.lawName);
    BookmarkService.isBookmarked(s.id).then((value) {
      if (mounted) setState(() => _isBookmarked = value);
    });
    _loadCategoryStyle();
    LegalDataRepository.loadSectionVersions(s.id).then((v) {
      if (mounted) setState(() => _versions = v);
    });
    if (s.relatedSectionIds.isNotEmpty) {
      LegalDataRepository.loadSections().then((all) {
        if (!mounted) return;
        setState(() {
          _relatedSections = all
              .where((item) => s.relatedSectionIds.contains(item.id))
              .toList();
        });
      });
    }
  }

  @override
  void dispose() {
    TtsService.instance.stop();
    super.dispose();
  }

  Future<void> _loadCategoryStyle() async {
    if (_section == null) return;
    final categories = await LegalDataRepository.loadCategories();
    final laws = await LegalDataRepository.loadLaws();
    if (!mounted) return;
    final lookup = SectionLookup(laws, categories);
    setState(() => _style = categoryStyleFor(lookup.categoryNameFor(section)));
  }

  Future<void> _toggleBookmark() async {
    if (_section == null) return;
    await BookmarkService.toggle(section.id);
    final value = await BookmarkService.isBookmarked(section.id);
    if (mounted) setState(() => _isBookmarked = value);
  }

  String _cleanTtsText(String raw) {
    return raw
        .replaceAll(RegExp(r'[*_#`\[\]]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _prepareTtsContent(LegalSection s) {
    final buffer = StringBuffer();
    buffer.write('${s.sectionNumber}. ${s.displayTitle}. ');
    if (s.displayQuickAnswer.isNotEmpty) {
      buffer.write('${tr("Quick Answer")}: ${s.displayQuickAnswer}. ');
    }
    if (s.displaySimpleExplanation.isNotEmpty) {
      buffer.write('${tr("In Simple Words")}: ${s.displaySimpleExplanation}. ');
    }
    if (s.hasRealLifeExample) {
      buffer.write('${tr("Real-Life Example")}: ${s.displayExampleSituation}. ${s.displayExampleExplanation}. ');
    }
    if (s.whatYouShouldDoList.isNotEmpty) {
      buffer.write('${tr("What You Should Do")}: ${s.whatYouShouldDoList.join(". ")}. ');
    }
    return _cleanTtsText(buffer.toString());
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

    if (_section == null) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(tr('Section Not Found'), style: GoogleFonts.inter(color: AppColors.textPrimary)),
        ),
        body: Center(
          child: Text(
            tr('The requested legal section could not be found.'),
            style: GoogleFonts.inter(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final s = section;

    return ValueListenableBuilder<String>(
      valueListenable: LocaleService.language,
      builder: (context, currentLanguage, _) {
        final ttsText = _prepareTtsContent(s);

        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            title: Text(
              s.sectionNumber,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              ValueListenableBuilder<String?>(
                valueListenable: TtsService.instance.currentlyPlayingId,
                builder: (context, playingId, _) {
                  final isPlaying = playingId == 'section_${s.id}';
                  return IconButton(
                    icon: Icon(
                      isPlaying ? Icons.stop_circle_rounded : Icons.volume_up_rounded,
                      color: isPlaying ? Colors.red : AppColors.accent,
                    ),
                    tooltip: tr(isPlaying ? 'Stop Reading' : 'Listen to Section'),
                    onPressed: () {
                      TtsService.instance.toggle(
                        text: ttsText,
                        id: 'section_${s.id}',
                      );
                    },
                  );
                },
              ),
              IconButton(
                icon: Icon(
                  _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  color: AppColors.accent,
                ),
                tooltip: tr(_isBookmarked ? 'Remove from Saved' : 'Save Section'),
                onPressed: _toggleBookmark,
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderCard(s),
                const SizedBox(height: 16),

                // 1. QUICK ANSWER CARD
                _buildQuickAnswerCard(s, ttsText),
                const SizedBox(height: 16),

                // 2. IN SIMPLE WORDS
                _buildInSimpleWordsCard(s),
                const SizedBox(height: 16),

                // 3. UNDERSTAND WITH AN EXAMPLE (Unified with Visual + Video)
                _buildRealLifeExampleCard(s),

                // 4. OPTIONAL STEP-BY-STEP VISUAL FLOW
                if (s.hasSteps) _buildStepByStepFlow(s),

                // 7. WHAT YOU SHOULD DO
                if (s.whatYouShouldDoList.isNotEmpty) _buildWhatYouShouldDoCard(s),

                const SizedBox(height: 10),
                Text(
                  tr('Detailed Legal Information & Statutory Sources'),
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),

                // 8. PROGRESSIVE DISCLOSURE ACCORDIONS
                if (s.keyElementsList.isNotEmpty)
                  _buildCollapsibleSection(
                    title: tr('Key Elements'),
                    icon: Icons.checklist_rounded,
                    accentColor: const Color(0xFF38BDF8),
                    isExpanded: _keyElementsExpanded,
                    onToggle: () => setState(() => _keyElementsExpanded = !_keyElementsExpanded),
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final elem in s.keyElementsList)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Container(
                                    width: 5,
                                    height: 5,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF38BDF8),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    elem,
                                    style: GoogleFonts.inter(
                                      color: AppColors.textSecondary,
                                      fontSize: 13.5,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                if (s.displayRelevantDocuments.isNotEmpty)
                  _buildCollapsibleSection(
                    title: s.documentsHeaderTitle,
                    icon: Icons.folder_copy_rounded,
                    accentColor: AppColors.success,
                    isExpanded: _documentsExpanded,
                    onToggle: () => setState(() => _documentsExpanded = !_documentsExpanded),
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.displayRelevantDocuments,
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 13.5,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          tr('Note: Specific documents depend on individual case facts. Consult legal counsel for mandatory filings.'),
                          style: GoogleFonts.inter(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),

                if (s.displayPunishment.isNotEmpty)
                  _buildCollapsibleSection(
                    title: s.consequencesHeaderTitle,
                    icon: s.consequencesType == 'order' ? Icons.gavel_rounded : Icons.shield_rounded,
                    accentColor: s.consequencesType == 'order' ? const Color(0xFF818CF8) : AppColors.danger,
                    isExpanded: _consequencesExpanded,
                    onToggle: () => setState(() => _consequencesExpanded = !_consequencesExpanded),
                    content: Text(
                      s.displayPunishment,
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 13.5,
                        height: 1.45,
                      ),
                    ),
                  ),

                if (_relatedSections.isNotEmpty)
                  _buildCollapsibleSection(
                    title: tr('Related Laws & Provisions'),
                    icon: Icons.link_rounded,
                    accentColor: _style.color,
                    isExpanded: _relatedLawsExpanded,
                    onToggle: () => setState(() => _relatedLawsExpanded = !_relatedLawsExpanded),
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final related in _relatedSections)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SectionDetailScreen(section: related),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.bg,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            related.lawName,
                                            style: GoogleFonts.inter(
                                              color: AppColors.accent,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 11,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${related.sectionNumber} — ${related.displayTitle}',
                                            style: GoogleFonts.inter(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                _buildCollapsibleSection(
                  title: (s.isVerifiedStatutoryText && s.legalText.isNotEmpty)
                      ? tr('Official Statutory Legal Text')
                      : tr('Plain-Language Legal Explanation'),
                  icon: Icons.menu_book_rounded,
                  accentColor: const Color(0xFFA855F7),
                  isExpanded: _statutoryTextExpanded,
                  onToggle: () => setState(() => _statutoryTextExpanded = !_statutoryTextExpanded),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.bg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          s.legalText.isNotEmpty ? s.legalText : s.displaySimpleExplanation,
                          style: GoogleFonts.inter(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        (s.isVerifiedStatutoryText && s.legalText.isNotEmpty)
                            ? ((LocaleService.isTelugu || LocaleService.isHindi)
                                ? tr('(Official bare act statutory text preserved in English to reflect official gazette publication.)')
                                : tr('(Exact statutory language transcribed directly from the official bare act.)'))
                            : tr('(Plain-language legal explanation. Consult official gazette for statutory bare act wording.)'),
                        style: GoogleFonts.inter(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 9. OFFICIAL SOURCE CARD
                _buildOfficialSourceCard(s),

                if (_versions.isNotEmpty) _buildVersionHistoryCard(),

                const SizedBox(height: 16),
                _buildGeneralDisclaimer(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderCard(LegalSection s) {
    final statusColor = s.isHistorical
        ? AppColors.warning
        : (s.isRepealed ? AppColors.danger : AppColors.success);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.lawName,
            style: GoogleFonts.inter(
              color: AppColors.accent,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            s.sectionNumber,
            style: GoogleFonts.outfit(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            s.displayTitle,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  s.statusDisplayLabel,
                  style: GoogleFonts.inter(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '${tr("LegalGuide Content Version")}: v${s.version}',
                  style: GoogleFonts.inter(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
              if (s.lastVerified != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    '${tr("Verified")}: ${s.lastVerified}',
                    style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAnswerCard(LegalSection s, String ttsText) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _style.color.withValues(alpha: 0.18),
            _style.color.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: _style.color.withValues(alpha: 0.4), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt_rounded, color: AppColors.warning, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tr('Quick Answer'),
                  style: GoogleFonts.inter(
                    color: AppColors.warning,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              ValueListenableBuilder<String?>(
                valueListenable: TtsService.instance.currentlyPlayingId,
                builder: (context, playingId, _) {
                  final isPlaying = playingId == 'section_${s.id}';
                  return InkWell(
                    onTap: () {
                      TtsService.instance.toggle(
                        text: ttsText,
                        id: 'section_${s.id}',
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isPlaying ? Colors.red : AppColors.warning).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: (isPlaying ? Colors.red : AppColors.warning).withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPlaying ? Icons.stop_rounded : Icons.volume_up_rounded,
                            size: 14,
                            color: isPlaying ? Colors.red : AppColors.warning,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            tr(isPlaying ? 'Stop' : 'Listen'),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isPlaying ? Colors.red : AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            s.displayQuickAnswer,
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 14.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInSimpleWordsCard(LegalSection s) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book_rounded, color: Color(0xFF38BDF8), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tr('In Simple Words'),
                  style: GoogleFonts.inter(
                    color: const Color(0xFF38BDF8),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            s.displaySimpleExplanation,
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          if (s.displayPurpose.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.track_changes_rounded, color: Color(0xFF22D3EE), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${tr("Purpose")}: ${s.displayPurpose}',
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRealLifeExampleCard(LegalSection s) {
    if (!s.hasRealLifeExample && !s.hasVisualExample && !s.hasVideoExample) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lightbulb_rounded, color: Color(0xFFF59E0B), size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tr('💡 Understand With an Example'),
                  style: GoogleFonts.inter(
                    color: const Color(0xFFF59E0B),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (s.displayExampleSituation.isNotEmpty) ...[
            Text(
              tr('Situation:'),
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              s.displayExampleSituation,
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 14,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 12),
          ],

          // 🖼️ Visual Example immediately follows Situation
          if (s.hasVisualExample) ...[
            _buildVisualContent(s),
            const SizedBox(height: 12),
          ],

          if (s.displayExampleExplanation.isNotEmpty) ...[
            Text(
              tr('How the law may apply:'),
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              s.displayExampleExplanation,
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 14,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 12),
          ],

          // 🎬 Watch the Example (Educational Video - optional)
          if (s.hasVideoExample) ...[
            _buildVideoContent(s),
            const SizedBox(height: 12),
          ],

          const Divider(color: AppColors.border, height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.textMuted, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  s.displayExampleDisclaimer.isNotEmpty
                      ? s.displayExampleDisclaimer
                      : tr('Fictional educational example. This scenario is provided only to help explain the legal concept and does not represent an actual case.'),
                  style: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVisualContent(LegalSection s) {
    final imageUri = s.visualImageUrl.trim();
    if (imageUri.isEmpty) return const SizedBox.shrink();

    final isAsset = imageUri.startsWith('assets/');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.image_outlined, color: Color(0xFF38BDF8), size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  tr('🖼️ Visual Example'),
                  style: GoogleFonts.inter(
                    color: const Color(0xFF38BDF8),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              InkWell(
                onTap: () => _showImageZoomDialog(context, imageUri, s.displayVisualCaption),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.zoom_in_rounded, color: Color(0xFF38BDF8), size: 15),
                      const SizedBox(width: 3),
                      Text(
                        tr('Zoom'),
                        style: GoogleFonts.inter(
                          color: const Color(0xFF38BDF8),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => _showImageZoomDialog(context, imageUri, s.displayVisualCaption),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: isAsset
                  ? Image.asset(
                      imageUri,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                    )
                  : Image.network(
                      imageUri,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, color: AppColors.textMuted, size: 12),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    tr('Illustrative example for educational purposes — not an actual case.'),
                    style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontSize: 10.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (s.displayVisualCaption.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '${tr("Caption:")} ${s.displayVisualCaption}',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showImageZoomDialog(BuildContext context, String imagePath, String caption) {
    showDialog(
      context: context,
      builder: (ctx) {
        final screenHeight = MediaQuery.sizeOf(ctx).height;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(12),
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              Container(
                constraints: BoxConstraints(maxHeight: screenHeight * 0.88),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.all(12),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: screenHeight * 0.65),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: InteractiveViewer(
                            panEnabled: true,
                            minScale: 1.0,
                            maxScale: 4.0,
                            child: imagePath.startsWith('assets/')
                                ? Image.asset(imagePath, fit: BoxFit.contain)
                                : Image.network(imagePath, fit: BoxFit.contain),
                          ),
                        ),
                      ),
                      if (caption.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          caption,
                          style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: CircleAvatar(
                  backgroundColor: Colors.black.withValues(alpha: 0.7),
                  radius: 18,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVideoContent(LegalSection s) {
    if (!s.hasVideoExample) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEC4899).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.play_circle_fill_rounded, color: Color(0xFFEC4899), size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  tr('🎬 Watch the Example'),
                  style: GoogleFonts.inter(
                    color: const Color(0xFFEC4899),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              if (s.videoDuration.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    s.videoDuration,
                    style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          if (s.videoTitle.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              s.videoTitle,
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 10),
          InkWell(
            onTap: () {
              final uri = Uri.tryParse(s.videoUrl);
              if (uri != null) launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEC4899).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFEC4899).withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_arrow_rounded, color: Color(0xFFEC4899), size: 18),
                  const SizedBox(width: 6),
                  Text(
                    tr('Watch Educational Video'),
                    style: GoogleFonts.inter(
                      color: const Color(0xFFEC4899),
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (s.videoTranscript.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.subtitles_rounded, color: AppColors.textMuted, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${tr("Transcript")}: ${s.videoTranscript}',
                      style: GoogleFonts.inter(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepByStepFlow(LegalSection s) {
    if (!s.hasSteps) return const SizedBox.shrink();

    final steps = s.exampleStepsList;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.linear_scale_rounded, color: Color(0xFF10B981), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tr('Step-by-Step Procedure Flow'),
                  style: GoogleFonts.inter(
                    color: const Color(0xFF10B981),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < steps.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF10B981), width: 1.2),
                  ),
                  child: Center(
                    child: Text(
                      '${steps[i].order}',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF10B981),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        steps[i].title,
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        steps[i].description,
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (i < steps.length - 1)
              Padding(
                padding: const EdgeInsets.only(left: 11),
                child: Container(
                  width: 2,
                  height: 16,
                  color: const Color(0xFF10B981).withValues(alpha: 0.3),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildWhatYouShouldDoCard(LegalSection s) {
    final items = s.whatYouShouldDoList;
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: const Color(0xFF06B6D4).withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF06B6D4), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tr('📋 What You Should Do'),
                  style: GoogleFonts.inter(
                    color: const Color(0xFF06B6D4),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Color(0xFF06B6D4),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCollapsibleSection({
    required String title,
    required IconData icon,
    required Color accentColor,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget content,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: isExpanded ? accentColor.withValues(alpha: 0.4) : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(icon, color: accentColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(color: AppColors.border, height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: content,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOfficialSourceCard(LegalSection s) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_rounded, color: AppColors.success, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tr('Official Source'),
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  tr('Verified'),
                  style: GoogleFonts.inter(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            s.sourceName.isNotEmpty ? s.sourceName : 'India Code — Ministry of Law & Justice, Govt. of India',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${tr("Source Type")}: ${s.sourceType}',
            style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11),
          ),
          Text(
            '${tr("Last Verified")}: ${s.lastVerified ?? "2024-07-01"}',
            style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () {
              final url = s.source.isNotEmpty ? s.source : 'https://www.indiacode.gov.in/';
              final uri = Uri.tryParse(url);
              if (uri != null) launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.open_in_new_rounded, color: AppColors.accent, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    tr('View Official Source'),
                    style: GoogleFonts.inter(
                      color: AppColors.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionHistoryCard() {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _showVersionHistory = !_showVersionHistory),
            child: Row(
              children: [
                const Icon(Icons.history_rounded, color: AppColors.accent, size: 18),
                const SizedBox(width: 8),
                Text(
                  '${tr("Version History")} (${_versions.length})',
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
                const Spacer(),
                Icon(
                  _showVersionHistory ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  color: AppColors.textMuted,
                  size: 20,
                ),
              ],
            ),
          ),
          if (_showVersionHistory) ...[
            const SizedBox(height: 12),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 12),
            for (final ver in _versions)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'v${ver.version} ${ver.effectiveDate != null ? "• ${ver.effectiveDate}" : ""}',
                      style: GoogleFonts.inter(
                        color: AppColors.accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    if (ver.changeSummary.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        ver.changeSummary,
                        style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildGeneralDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined, color: AppColors.textMuted, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tr('This information is provided for general educational and legal awareness purposes. It is not a substitute for advice from a qualified legal professional.'),
              style: GoogleFonts.inter(
                color: AppColors.textMuted,
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
