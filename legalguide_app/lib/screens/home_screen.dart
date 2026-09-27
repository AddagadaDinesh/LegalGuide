import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../localization/app_strings.dart';
import '../models/category.dart';
import '../models/law.dart';
import '../models/legal_matter.dart';
import '../models/legal_section.dart';
import '../repositories/legal_data_repository.dart';
import '../services/auth_service.dart';
import '../services/bookmark_service.dart';
import '../services/search_history_service.dart';
import '../services/view_count_service.dart';
import '../theme/app_theme.dart';
import '../utils/section_lookup.dart';
import '../widgets/icon_badge.dart';
import '../widgets/legal_section_card.dart';
import '../widgets/section_heading.dart';
import 'arrest_detention_screen.dart';
import 'category_overview_screen.dart';
import 'documents_screen.dart';
import 'emergency_guide_screen.dart';
import 'explore_laws_screen.dart';
import 'legal_help_screen.dart';
import 'railway_rules_screen.dart';
import 'section_detail_screen.dart';
import 'traffic_rules_screen.dart';

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
    final results = await Future.wait([
      LegalDataRepository.hasSyncedBefore(),
      LegalDataRepository.loadCategories(),
      LegalDataRepository.loadLaws(),
      LegalDataRepository.loadSections(),
      LegalDataRepository.loadMatters(),
      BookmarkService.getBookmarkedIds(),
      ViewCountService.getAllCounts(),
      SearchHistoryService.getTopQueries(),
    ]);
    final hasSyncedBefore = results[0] as bool;
    final categories = results[1] as List<Category>;
    final laws = results[2] as List<Law>;
    final sections = results[3] as List<LegalSection>;
    final matters = results[4] as List<LegalMatter>;
    final bookmarks = results[5] as Set<int>;
    final counts = results[6] as Map<int, int>;
    final topSearches = results[7] as List<String>;

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
    final topCommon = commonlyReferenced.take(3).toList();
    final commonIds = topCommon.map((s) => s.id).toSet();
    final topFrequent = frequent.where((s) => !commonIds.contains(s.id)).take(3).toList();

    setState(() {
      _neverSynced = !synced && !hasSyncedBefore;
      _categories = categories;
      _frequentSections = topFrequent;
      _commonlyReferenced = topCommon;
      _popularSearches = topSearches.isNotEmpty ? topSearches.toSet().toList() : _fallbackSearchSuggestions;
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

  Widget _quickAccessCard(String label, IconData icon, Color color, VoidCallback onTap) {
    return SizedBox(
      width: 102,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconBadge(icon: icon, color: color),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600, height: 1.25),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryCard(Category category) {
    final style = categoryStyleFor(category.name);
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CategoryOverviewScreen(category: category)),
      ),
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        width: 132,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            IconBadge(icon: style.icon, color: style.color, size: 38, iconSize: 18),
            const SizedBox(height: 10),
            Text(
              category.displayName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12.5, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lookup = _lookup;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.accent,
          backgroundColor: AppColors.surface,
          child: (_loading || lookup == null)
              ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: AppColors.accentGradient,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.balance_rounded, color: Colors.white, size: 26),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'LegalGuide',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                ValueListenableBuilder<String?>(
                                  valueListenable: AuthService.currentUsername,
                                  builder: (context, username, _) {
                                    return Text(
                                      username != null
                                          ? '${tr("Welcome,")} $username'
                                          : tr('Simplified Legal Knowledge & Assistance'),
                                      style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.85), fontSize: 12.5),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    InkWell(
                      onTap: widget.onOpenExplore,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search_rounded, color: AppColors.accent),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                tr('Search laws, section numbers, topics...'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    SectionHeading(title: tr('Quick Actions'), icon: Icons.bolt_rounded),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _quickAccessCard(tr('Search Laws'), Icons.search_rounded, AppColors.accent, widget.onOpenExplore),
                        _quickAccessCard(tr('Ask AI'), Icons.chat_bubble_rounded, const Color(0xFFA78BFA), widget.onOpenAssistant),
                        _quickAccessCard(tr('Arrest &\nDetention'), Icons.local_police_rounded, const Color(0xFFF59E0B), () {
                          Navigator.push(context,
                              MaterialPageRoute(builder: (context) => const ArrestDetentionScreen()));
                        }),
                        _quickAccessCard(tr('Legal\nDocuments'), Icons.description_rounded, const Color(0xFF14B8A6), () {
                          Navigator.push(
                              context, MaterialPageRoute(builder: (context) => const DocumentsScreen()));
                        }),
                        _quickAccessCard(tr('Need Legal\nHelp'), Icons.support_agent_rounded, const Color(0xFFF43F5E), () {
                          Navigator.push(
                              context, MaterialPageRoute(builder: (context) => const LegalHelpScreen()));
                        }),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Emergency Rights Quick-Guide Banner
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const EmergencyGuideScreen()),
                        );
                      },
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF991B1B), Color(0xFFDC2626)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFDC2626).withValues(alpha: 0.28),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.shield_rounded, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          tr('Emergency Rights Guide'),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.25),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          tr('HELP NOW'),
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    tr('Police stops, traffic challans, cyber fraud & women safety rights'),
                                    style: GoogleFonts.inter(
                                      color: Colors.white.withValues(alpha: 0.88),
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Railway Rules Banner
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RailwayRulesScreen()),
                        );
                      },
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0369A1), Color(0xFF0284C7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.train_rounded, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tr('Indian Railway Rules & Fines'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    tr('Penalties, ticketless travel, chain pulling & passenger rights'),
                                    style: GoogleFonts.inter(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Traffic Rules & Driver Rights Banner
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const TrafficRulesScreen()),
                        );
                      },
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFB45309), Color(0xFFD97706)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD97706).withValues(alpha: 0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.traffic_rounded, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tr('Traffic Rules & Driver Rights'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    tr('MV Act 2019 fines, e-challan disputes & citizen driver protections'),
                                    style: GoogleFonts.inter(
                                      color: Colors.white.withValues(alpha: 0.88),
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_neverSynced) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20.0),
                        child: Column(
                          children: [
                            const Icon(Icons.cloud_off_rounded, color: AppColors.textMuted, size: 40),
                            const SizedBox(height: 16),
                            Text(
                              tr("You're offline and haven't synced any legal data yet.\n"
                                  'Connect to the internet and pull down to refresh.'),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      SectionHeading(title: tr('Popular Searches'), icon: Icons.trending_up_rounded),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final query in _popularSearches)
                            ActionChip(
                              avatar: const Icon(Icons.search_rounded, size: 14, color: AppColors.accent),
                              label: Text(query),
                              backgroundColor: AppColors.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                                side: const BorderSide(color: AppColors.border),
                              ),
                              labelStyle: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 12),
                              onPressed: () => _openSearchSuggestion(query),
                            ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      SectionHeading(title: tr('Explore Laws'), icon: Icons.grid_view_rounded),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 122,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [for (final category in _categories) _categoryCard(category)],
                        ),
                      ),
                      const SizedBox(height: 28),
                      SectionHeading(title: tr('Commonly Referenced Sections'), icon: Icons.link_rounded),
                      const SizedBox(height: 12),
                      if (_commonlyReferenced.isEmpty)
                        Text(
                          tr('Sections linked from multiple topics will show up here.'),
                          style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
                        )
                      else
                        for (final section in _commonlyReferenced)
                          LegalSectionCard(
                            section: section,
                            lawShortName: lookup.lawShortNameFor(section),
                            breadcrumb: lookup.breadcrumbFor(section),
                            isBookmarked: _bookmarkedIds.contains(section.id),
                            isFrequentlyViewed: false,
                            accentColor: categoryStyleFor(lookup.categoryNameFor(section)).color,
                            onBookmarkToggle: () => _toggleBookmark(section.id),
                            onTap: () => _openSection(section),
                          ),
                      const SizedBox(height: 16),
                      SectionHeading(title: tr('Frequently Viewed'), icon: Icons.history_rounded),
                      const SizedBox(height: 12),
                      if (_frequentSections.isEmpty)
                        Text(
                          tr('Sections you open a few times will show up here.'),
                          style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
                        )
                      else
                        for (final section in _frequentSections)
                          LegalSectionCard(
                            section: section,
                            lawShortName: lookup.lawShortNameFor(section),
                            breadcrumb: lookup.breadcrumbFor(section),
                            isBookmarked: _bookmarkedIds.contains(section.id),
                            isFrequentlyViewed: true,
                            accentColor: categoryStyleFor(lookup.categoryNameFor(section)).color,
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
