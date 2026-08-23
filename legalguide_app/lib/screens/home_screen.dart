import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/category.dart';
import '../models/legal_section.dart';
import '../repositories/legal_data_repository.dart';
import '../services/bookmark_service.dart';
import '../services/search_history_service.dart';
import '../services/view_count_service.dart';
import '../utils/section_lookup.dart';
import '../widgets/legal_section_card.dart';
import 'arrest_detention_screen.dart';
import 'category_overview_screen.dart';
import 'documents_screen.dart';
import 'explore_laws_screen.dart';
import 'legal_help_screen.dart';
import 'section_detail_screen.dart';

const _fallbackSearchSuggestions = ['theft', 'arrest', 'cheating', 'murder', 'article 21'];

class HomeScreen extends StatefulWidget {
  final VoidCallback onOpenExplore;
  final VoidCallback onOpenAssistant;
  final ValueNotifier<int> bookmarkVersion;

  const HomeScreen({
    super.key,
    required this.onOpenExplore,
    required this.onOpenAssistant,
    required this.bookmarkVersion,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Category> _categories = [];
  List<LegalSection> _frequentSections = [];
  List<LegalSection> _commonlyReferenced = [];
  List<String> _popularSearches = [];
  Set<int> _bookmarkedIds = {};
  SectionLookup? _lookup;
  bool _loading = true;
  bool _neverSynced = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final synced = await LegalDataRepository.syncAll();
    final hasSyncedBefore = await LegalDataRepository.hasSyncedBefore();
    final categories = await LegalDataRepository.loadCategories();
    final laws = await LegalDataRepository.loadLaws();
    final sections = await LegalDataRepository.loadSections();
    final matters = await LegalDataRepository.loadMatters();
    final bookmarks = await BookmarkService.getBookmarkedIds();
    final counts = await ViewCountService.getAllCounts();
    final topSearches = await SearchHistoryService.getTopQueries();

    final frequent = sections
        .where((s) => (counts[s.id] ?? 0) >= ViewCountService.frequentThreshold)
        .toList()
      ..sort((a, b) => (counts[b.id] ?? 0).compareTo(counts[a.id] ?? 0));

    final referenceCounts = <int, int>{};
    for (final matter in matters) {
      for (final id in matter.relatedSectionIds) {
        referenceCounts[id] = (referenceCounts[id] ?? 0) + 1;
      }
    }
    final commonlyReferenced = sections
        .where((s) => (referenceCounts[s.id] ?? 0) > 0)
        .toList()
      ..sort((a, b) => (referenceCounts[b.id] ?? 0).compareTo(referenceCounts[a.id] ?? 0));

    if (!mounted) return;
    setState(() {
      _neverSynced = !synced && !hasSyncedBefore;
      _categories = categories;
      _frequentSections = frequent.take(3).toList();
      _commonlyReferenced = commonlyReferenced.take(3).toList();
      _popularSearches = topSearches.isNotEmpty ? topSearches : _fallbackSearchSuggestions;
      _bookmarkedIds = bookmarks;
      _lookup = SectionLookup(laws, categories);
      _loading = false;
    });
  }

  Future<void> _toggleBookmark(int sectionId) async {
    await BookmarkService.toggle(sectionId);
    widget.bookmarkVersion.value++;
    final bookmarks = await BookmarkService.getBookmarkedIds();
    if (mounted) setState(() => _bookmarkedIds = bookmarks);
  }

  void _openSection(LegalSection section) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SectionDetailScreen(section: section)),
    );
    _loadData();
  }

  void _openSearchSuggestion(String query) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExploreLawsScreen(initialQuery: query, showAppBar: true),
      ),
    );
  }

  Widget _quickAccessCard(String label, IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: 100,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: const Color(0xFF6366F1), size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lookup = _lookup;
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: const Color(0xFF6366F1),
          backgroundColor: const Color(0xFF1E293B),
          child: (_loading || lookup == null)
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LegalGuide',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              'Simplified Legal Knowledge & Assistance',
                              style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF334155)),
                          ),
                          child: const Icon(Icons.gavel_rounded, color: Color(0xFF6366F1), size: 24),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    InkWell(
                      onTap: widget.onOpenExplore,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF334155)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: Color(0xFF6366F1)),
                            const SizedBox(width: 10),
                            Text(
                              'Search laws, section numbers, topics...',
                              style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('Quick Actions',
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _quickAccessCard('Search Laws', Icons.search, widget.onOpenExplore),
                        _quickAccessCard('Ask AI', Icons.chat_bubble_outline_rounded, widget.onOpenAssistant),
                        _quickAccessCard('Arrest &\nDetention', Icons.shield_outlined, () {
                          Navigator.push(context,
                              MaterialPageRoute(builder: (context) => const ArrestDetentionScreen()));
                        }),
                        _quickAccessCard('Legal\nDocuments', Icons.description_outlined, () {
                          Navigator.push(
                              context, MaterialPageRoute(builder: (context) => const DocumentsScreen()));
                        }),
                        _quickAccessCard('Need Legal\nHelp', Icons.support_agent_rounded, () {
                          Navigator.push(
                              context, MaterialPageRoute(builder: (context) => const LegalHelpScreen()));
                        }),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (_neverSynced) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20.0),
                        child: Column(
                          children: [
                            const Icon(Icons.cloud_off_rounded, color: Color(0xFF64748B), size: 40),
                            const SizedBox(height: 16),
                            Text(
                              "You're offline and haven't synced any legal data yet.\n"
                              'Connect to the internet and pull down to refresh.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(color: const Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Text('Popular Searches',
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final query in _popularSearches)
                            ActionChip(
                              label: Text(query),
                              backgroundColor: const Color(0xFF1E293B),
                              side: const BorderSide(color: Color(0xFF334155)),
                              labelStyle: GoogleFonts.inter(color: Colors.white, fontSize: 12),
                              onPressed: () => _openSearchSuggestion(query),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Browse Legal Categories',
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 36,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            for (final category in _categories) ...[
                              ActionChip(
                                label: Text(category.name),
                                backgroundColor: const Color(0xFF1E293B),
                                side: const BorderSide(color: Color(0xFF334155)),
                                labelStyle: GoogleFonts.inter(color: Colors.white, fontSize: 12),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CategoryOverviewScreen(category: category),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Commonly Referenced Sections',
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      if (_commonlyReferenced.isEmpty)
                        Text(
                          'Sections linked from multiple topics will show up here.',
                          style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13),
                        )
                      else
                        for (final section in _commonlyReferenced)
                          LegalSectionCard(
                            section: section,
                            lawShortName: lookup.lawShortNameFor(section),
                            breadcrumb: lookup.breadcrumbFor(section),
                            isBookmarked: _bookmarkedIds.contains(section.id),
                            isFrequentlyViewed: false,
                            onBookmarkToggle: () => _toggleBookmark(section.id),
                            onTap: () => _openSection(section),
                          ),
                      const SizedBox(height: 24),
                      Text(
                        'Frequently Viewed',
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      if (_frequentSections.isEmpty)
                        Text(
                          'Sections you open a few times will show up here.',
                          style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13),
                        )
                      else
                        for (final section in _frequentSections)
                          LegalSectionCard(
                            section: section,
                            lawShortName: lookup.lawShortNameFor(section),
                            breadcrumb: lookup.breadcrumbFor(section),
                            isBookmarked: _bookmarkedIds.contains(section.id),
                            isFrequentlyViewed: true,
                            onBookmarkToggle: () => _toggleBookmark(section.id),
                            onTap: () => _openSection(section),
                          ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
