import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/legal_section.dart';
import '../repositories/legal_data_repository.dart';
import '../services/bookmark_service.dart';
import '../services/view_count_service.dart';
import '../theme/app_theme.dart';
import '../utils/section_lookup.dart';
import '../widgets/legal_section_card.dart';
import 'section_detail_screen.dart';

class SavedScreen extends StatefulWidget {
  final ValueNotifier<int> bookmarkVersion;

  const SavedScreen({super.key, required this.bookmarkVersion});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  List<LegalSection> _saved = [];
  Map<int, int> _viewCounts = {};
  SectionLookup? _lookup;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    widget.bookmarkVersion.addListener(_loadData);
    _loadData();
  }

  @override
  void dispose() {
    widget.bookmarkVersion.removeListener(_loadData);
    super.dispose();
  }

  Future<void> _loadData() async {
    final categories = await LegalDataRepository.loadCategories();
    final laws = await LegalDataRepository.loadLaws();
    final sections = await LegalDataRepository.loadSections();
    final bookmarkedIds = await BookmarkService.getBookmarkedIds();
    final counts = await ViewCountService.getAllCounts();
    if (!mounted) return;
    setState(() {
      _lookup = SectionLookup(laws, categories);
      _saved = sections.where((s) => bookmarkedIds.contains(s.id)).toList();
      _viewCounts = counts;
      _loading = false;
    });
  }

  Future<void> _toggleBookmark(int sectionId) async {
    await BookmarkService.toggle(sectionId);
    widget.bookmarkVersion.value++;
  }

  @override
  Widget build(BuildContext context) {
    final lookup = _lookup;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: _loading || lookup == null
            ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                      child: Row(
                        children: [
                          const Icon(Icons.bookmark_rounded, color: AppColors.accent, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'My Saved',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                      child: Text(
                        _saved.isEmpty ? 'Nothing saved yet' : '${_saved.length} section${_saved.length == 1 ? '' : 's'} bookmarked',
                        style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ),
                  ),
                  if (_saved.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
                        child: Column(
                          children: [
                            const Icon(Icons.bookmark_border_rounded,
                                color: AppColors.textMuted, size: 40),
                            const SizedBox(height: 16),
                            Text(
                              'No saved sections yet — tap the bookmark icon on any '
                              'section to save it here.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final section = _saved[index];
                            return LegalSectionCard(
                              section: section,
                              lawShortName: lookup.lawShortNameFor(section),
                              breadcrumb: lookup.breadcrumbFor(section),
                              isBookmarked: true,
                              isFrequentlyViewed: (_viewCounts[section.id] ?? 0) >=
                                  ViewCountService.frequentThreshold,
                              accentColor: categoryStyleFor(lookup.categoryNameFor(section)).color,
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
                            );
                          },
                          childCount: _saved.length,
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                ],
              ),
      ),
    );
  }
}
