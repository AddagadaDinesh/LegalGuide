import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../localization/app_strings.dart';
import '../models/legal_section.dart';
import '../repositories/legal_data_repository.dart';
import '../services/bookmark_service.dart';
import '../services/locale_service.dart';
import '../services/view_count_service.dart';
import '../theme/app_theme.dart';
import '../utils/section_lookup.dart';
import '../utils/section_visual.dart';

class SectionDetailScreen extends StatefulWidget {
  final LegalSection section;

  const SectionDetailScreen({super.key, required this.section});

  @override
  State<SectionDetailScreen> createState() => _SectionDetailScreenState();
}

class _SectionDetailScreenState extends State<SectionDetailScreen> {
  bool _isBookmarked = false;
  List<LegalSection> _relatedSections = [];
  CategoryStyle _style = categoryStyleFor('');

  LegalSection get section => widget.section;

  @override
  void initState() {
    super.initState();
    ViewCountService.recordView(section.id);
    BookmarkService.isBookmarked(section.id).then((value) {
      if (mounted) setState(() => _isBookmarked = value);
    });
    _loadCategoryStyle();
    if (section.relatedSectionIds.isNotEmpty) {
      LegalDataRepository.loadSections().then((all) {
        if (!mounted) return;
        setState(() {
          _relatedSections = all
              .where((s) => section.relatedSectionIds.contains(s.id))
              .toList();
        });
      });
    }
  }

  Future<void> _loadCategoryStyle() async {
    final categories = await LegalDataRepository.loadCategories();
    final laws = await LegalDataRepository.loadLaws();
    if (!mounted) return;
    final lookup = SectionLookup(laws, categories);
    setState(() => _style = categoryStyleFor(lookup.categoryNameFor(section)));
  }

  Future<void> _toggleBookmark() async {
    await BookmarkService.toggle(section.id);
    final value = await BookmarkService.isBookmarked(section.id);
    if (mounted) setState(() => _isBookmarked = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          section.sectionNumber,
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
          IconButton(
            icon: Icon(
              _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: AppColors.accent,
            ),
            onPressed: _toggleBookmark,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVisualBanner(),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(_style.icon, color: _style.color, size: 16),
                const SizedBox(width: 6),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: _style.color.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      section.sectionNumber.toUpperCase(),
                      style: GoogleFonts.inter(
                        color: _style.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (section.badge.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF064E3B),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  section.badge,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF6EE7B7),
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              section.displayTitle,
              style: GoogleFonts.outfit(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 24),

            _buildHighlightBox(
              title: tr('Key Takeaway (Plain Explanation)'),
              icon: Icons.lightbulb_rounded,
              content: section.displaySimpleExplanation,
              color: _style.color,
            ),
            const SizedBox(height: 16),

            if (section.purpose.isNotEmpty)
              _buildDetailBox(
                title: tr('Purpose & Legal Context'),
                icon: Icons.track_changes_rounded,
                content: section.displayPurpose,
                accentColor: const Color(0xFF22D3EE),
              ),
            if (section.purpose.isNotEmpty) const SizedBox(height: 16),

            if (section.keyElementsList.isNotEmpty)
              _buildBulletBox(
                title: tr('Key Elements'),
                icon: Icons.checklist_rounded,
                items: section.keyElementsList,
                accentColor: const Color(0xFF38BDF8),
              ),
            if (section.keyElementsList.isNotEmpty) const SizedBox(height: 16),

            if (section.punishment.isNotEmpty)
              _buildDetailBox(
                title: tr('Punishment & Penalties'),
                icon: Icons.gavel_rounded,
                content: section.displayPunishment,
                accentColor: AppColors.danger,
              ),
            if (section.punishment.isNotEmpty) const SizedBox(height: 16),

            if (section.relevantInformationList.isNotEmpty)
              _buildBulletBox(
                title: tr('What Information May Matter'),
                icon: Icons.fact_check_rounded,
                items: section.relevantInformationList,
                accentColor: AppColors.warning,
              ),
            if (section.relevantInformationList.isNotEmpty) const SizedBox(height: 16),

            if (section.relevantDocuments.isNotEmpty)
              _buildDetailBox(
                title: tr('Required / Relevant Documents'),
                icon: Icons.folder_copy_rounded,
                content: section.displayRelevantDocuments,
                accentColor: AppColors.success,
              ),
            if (section.relevantDocuments.isNotEmpty) const SizedBox(height: 16),

            _buildDetailBox(
              title: tr('Official Statutory Legal Text'),
              icon: Icons.menu_book_rounded,
              content: section.legalText,
              accentColor: const Color(0xFFA855F7),
              note: LocaleService.isTelugu
                  ? tr('(Official text is kept in English to preserve its exact legal wording.)')
                  : null,
            ),
            const SizedBox(height: 24),

            if (_relatedSections.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.link_rounded, color: _style.color, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    tr('Related Legal Provisions'),
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              for (final related in _relatedSections)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.card),
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
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  related.sectionNumber,
                                  style: GoogleFonts.inter(
                                    color: _style.color,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  related.displayTitle,
                                  style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13),
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
              const SizedBox(height: 16),
            ],

            if (section.source.isNotEmpty || section.lastVerified != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_rounded,
                        color: AppColors.success, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${tr("Verified from")} ${section.source.isEmpty ? tr("Official Gazette") : section.source}'
                        '${section.lastVerified != null ? " • ${tr("Last updated")} ${section.lastVerified}" : ""}',
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisualBanner() {
    final icon = sectionIconFor(section);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_style.color.withValues(alpha: 0.85), _style.color.withValues(alpha: 0.55)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              section.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightBox({
    required String title,
    required IconData icon,
    required String content,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0.08)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.warning, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletBox({
    required String title,
    required IconData icon,
    required List<String> items,
    required Color accentColor,
  }) {
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
              Icon(icon, color: accentColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final item in items)
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
                      decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 14,
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

  Widget _buildDetailBox({
    required String title,
    required IconData icon,
    required String content,
    required Color accentColor,
    String? note,
  }) {
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
              Icon(icon, color: accentColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.45,
            ),
          ),
          if (note != null) ...[
            const SizedBox(height: 8),
            Text(
              note,
              style: GoogleFonts.inter(
                color: AppColors.textMuted,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
