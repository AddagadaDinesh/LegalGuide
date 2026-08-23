import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/category.dart';
import '../models/law.dart';
import '../models/legal_matter.dart';
import '../repositories/legal_data_repository.dart';
import '../services/bookmark_service.dart';
import '../services/view_count_service.dart';
import '../theme/app_theme.dart';
import '../utils/section_lookup.dart';
import '../widgets/icon_badge.dart';
import '../widgets/legal_section_card.dart';
import 'section_detail_screen.dart';

class MatterDetailScreen extends StatefulWidget {
  final LegalMatter matter;

  const MatterDetailScreen({super.key, required this.matter});

  @override
  State<MatterDetailScreen> createState() => _MatterDetailScreenState();
}

class _MatterDetailScreenState extends State<MatterDetailScreen> {
  List<Category> _categories = [];
  List<Law> _laws = [];
  bool _loading = true;
  Set<int> _bookmarkedIds = {};
  Map<int, int> _viewCounts = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final categories = await LegalDataRepository.loadCategories();
    final laws = await LegalDataRepository.loadLaws();
    final bookmarks = await BookmarkService.getBookmarkedIds();
    final counts = await ViewCountService.getAllCounts();
    if (!mounted) return;
    setState(() {
      _categories = categories;
      _laws = laws;
      _bookmarkedIds = bookmarks;
      _viewCounts = counts;
      _loading = false;
    });
  }

  Future<void> _toggleBookmark(int sectionId) async {
    await BookmarkService.toggle(sectionId);
    final bookmarks = await BookmarkService.getBookmarkedIds();
    if (mounted) setState(() => _bookmarkedIds = bookmarks);
  }

  @override
  Widget build(BuildContext context) {
    final matter = widget.matter;
    final lookup = SectionLookup(_laws, _categories);
    final matchingCategories = _categories.where((c) => c.id == matter.categoryId);
    final category = matchingCategories.isEmpty ? null : matchingCategories.first;
    final style = categoryStyleFor(category?.name ?? '');

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(matter.name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: style.color))
          : FutureBuilder(
              future: LegalDataRepository.loadSections(),
              builder: (context, snapshot) {
                final allSections = snapshot.data ?? [];
                final sections = allSections
                    .where((s) => matter.relatedSectionIds.contains(s.id))
                    .toList();

                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(color: style.color.withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconBadge(icon: style.icon, color: style.color),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (category != null)
                                  Text(category.name.toUpperCase(),
                                      style: GoogleFonts.inter(
                                          color: style.color, fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
                                const SizedBox(height: 4),
                                Text(
                                  matter.description.isNotEmpty ? matter.description : matter.name,
                                  style: GoogleFonts.inter(color: const Color(0xFFCBD5E1), fontSize: 13.5, height: 1.5),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${sections.length} legal section${sections.length == 1 ? '' : 's'} linked',
                                  style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11.5, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (sections.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 30.0),
                        child: Column(
                          children: [
                            const Icon(Icons.hourglass_empty_rounded, color: AppColors.textMuted, size: 36),
                            const SizedBox(height: 12),
                            Text(
                              'Verified legal sections for this topic are not available yet.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    else
                      for (final section in sections)
                        LegalSectionCard(
                          section: section,
                          lawShortName: lookup.lawShortNameFor(section),
                          breadcrumb: lookup.breadcrumbFor(section),
                          isBookmarked: _bookmarkedIds.contains(section.id),
                          isFrequentlyViewed: (_viewCounts[section.id] ?? 0) >=
                              ViewCountService.frequentThreshold,
                          accentColor: style.color,
                          onBookmarkToggle: () => _toggleBookmark(section.id),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SectionDetailScreen(section: section),
                              ),
                            );
                            _loadData();
                          },
                        ),
                  ],
                );
              },
            ),
    );
  }
}
