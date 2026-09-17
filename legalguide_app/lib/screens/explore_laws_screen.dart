import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../localization/app_strings.dart';
import '../models/category.dart';
import '../models/legal_matter.dart';
import '../models/legal_section.dart';
import '../repositories/legal_data_repository.dart';
import '../services/bookmark_service.dart';
import '../services/search_history_service.dart';
import '../services/view_count_service.dart';
import '../theme/app_theme.dart';
import '../utils/section_lookup.dart';
import '../widgets/icon_badge.dart';
import '../widgets/legal_section_card.dart';
import '../widgets/section_heading.dart';
import 'category_overview_screen.dart';
import 'matter_detail_screen.dart';
import 'section_detail_screen.dart';

class ExploreLawsScreen extends StatefulWidget {
  final int? lockedCategoryId;
  final String title;
  final bool showCategoryFilterBar;
  final bool showAppBar;
  final String? initialQuery;

  const ExploreLawsScreen({
    super.key,
    this.lockedCategoryId,
    this.title = 'Explore Laws',
    this.showCategoryFilterBar = true,
    this.showAppBar = false,
    this.initialQuery,
  });

  @override
  State<ExploreLawsScreen> createState() => _ExploreLawsScreenState();
}

class _ExploreLawsScreenState extends State<ExploreLawsScreen> {
  List<Category> _categories = [];
  List<LegalMatter> _matters = [];
  List<LegalSection> _sections = [];
  Set<int> _bookmarkedIds = {};
  Map<int, int> _viewCounts = {};
  SectionLookup? _lookup;
  bool _loading = true;

  int? _selectedCategoryId;
  late final TextEditingController _searchController;
  String _query = '';
  Timer? _searchRecordDebounce;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.lockedCategoryId;
    _query = widget.initialQuery ?? '';
    _searchController = TextEditingController(text: _query);
    _loadData();
  }

  Future<void> _loadData() async {
    final categories = await LegalDataRepository.loadCategories();
    final laws = await LegalDataRepository.loadLaws();
    final sections = await LegalDataRepository.loadSections();
    final matters = await LegalDataRepository.loadMatters();
    final bookmarks = await BookmarkService.getBookmarkedIds();
    final counts = await ViewCountService.getAllCounts();
    setState(() {
      _categories = categories;
      _sections = sections;
      _matters = matters;
      _bookmarkedIds = bookmarks;
      _viewCounts = counts;
      _lookup = SectionLookup(laws, categories);
      _loading = false;
    });
  }

  void _onQueryChanged(String value) {
    setState(() => _query = value.trim());
    _searchRecordDebounce?.cancel();
    _searchRecordDebounce = Timer(const Duration(milliseconds: 900), () {
      SearchHistoryService.recordQuery(value);
    });
  }

  @override
  void dispose() {
    _searchRecordDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  List<Category> get _matchedCategories {
    if (_query.isEmpty) return [];
    final q = _query.toLowerCase();
    return _categories.where((c) => c.name.toLowerCase().contains(q)).toList();
  }

  List<LegalMatter> get _matchedMatters {
    if (_query.isEmpty) return [];
    final q = _query.toLowerCase();
    return _matters
        .where((m) => m.name.toLowerCase().contains(q) || m.description.toLowerCase().contains(q))
        .toList();
  }

  List<LegalSection> get _filtered {
    final lookup = _lookup;
    if (lookup == null) return [];
    return _sections.where((section) {
      if (_selectedCategoryId != null) {
        final category = lookup.categoryFor(section);
        if (category?.id != _selectedCategoryId) return false;
      }
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return section.sectionNumber.toLowerCase().contains(q) ||
          section.title.toLowerCase().contains(q) ||
          section.simpleExplanation.toLowerCase().contains(q) ||
          section.legalText.toLowerCase().contains(q) ||
          section.relevantDocuments.toLowerCase().contains(q) ||
          section.keywords.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _toggleBookmark(int sectionId) async {
    await BookmarkService.toggle(sectionId);
    final bookmarks = await BookmarkService.getBookmarkedIds();
    setState(() => _bookmarkedIds = bookmarks);
  }

  void _openSection(LegalSection section) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SectionDetailScreen(section: section)),
    );
    final counts = await ViewCountService.getAllCounts();
    final bookmarks = await BookmarkService.getBookmarkedIds();
    if (mounted) {
      setState(() {
        _viewCounts = counts;
        _bookmarkedIds = bookmarks;
      });
    }
  }

  Widget _buildContent() {
    final lookup = _lookup;
    if (_loading || lookup == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

    final filtered = _filtered;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!widget.showAppBar)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Text(
                      tr(widget.title),
                      style: GoogleFonts.outfit(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                TextField(
                  controller: _searchController,
                  style: GoogleFonts.inter(color: AppColors.textPrimary),
                  onChanged: _onQueryChanged,
                  decoration: InputDecoration(
                    hintText: tr('Search laws, section numbers, topics...'),
                    hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.accent),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
                    ),
                  ),
                ),
                if (widget.showCategoryFilterBar) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        ChoiceChip(
                          label: Text(tr('All')),
                          selected: _selectedCategoryId == null,
                          onSelected: (_) => setState(() => _selectedCategoryId = null),
                          selectedColor: AppColors.accent,
                          backgroundColor: AppColors.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            side: const BorderSide(color: AppColors.border),
                          ),
                          labelStyle: GoogleFonts.inter(
                            color: _selectedCategoryId == null ? Colors.white : AppColors.textPrimary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        for (final category in _categories) ...[
                          ChoiceChip(
                            label: Text(category.displayName),
                            selected: _selectedCategoryId == category.id,
                            onSelected: (_) => setState(() => _selectedCategoryId = category.id),
                            selectedColor: categoryStyleFor(category.name).color,
                            backgroundColor: AppColors.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                              side: const BorderSide(color: AppColors.border),
                            ),
                            labelStyle: GoogleFonts.inter(
                              color: _selectedCategoryId == category.id ? Colors.white : AppColors.textPrimary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_query.isNotEmpty && (_matchedCategories.isNotEmpty || _matchedMatters.isNotEmpty))
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_matchedCategories.isNotEmpty) ...[
                    SectionHeading(title: '${tr("Categories")} (${_matchedCategories.length})'),
                    const SizedBox(height: 8),
                    for (final category in _matchedCategories)
                      _buildResultTile(
                        icon: categoryStyleFor(category.name).icon,
                        color: categoryStyleFor(category.name).color,
                        title: category.displayName,
                        subtitle: category.displayDescription,
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (context) => CategoryOverviewScreen(category: category))),
                      ),
                    const SizedBox(height: 12),
                  ],
                  if (_matchedMatters.isNotEmpty) ...[
                    SectionHeading(title: '${tr("Topics")} (${_matchedMatters.length})'),
                    const SizedBox(height: 8),
                    for (final matter in _matchedMatters)
                      _buildResultTile(
                        icon: matter.isAvailable ? Icons.topic_rounded : Icons.hourglass_empty_rounded,
                        color: matter.isAvailable ? AppColors.accent : AppColors.textMuted,
                        title: matter.displayName,
                        subtitle: matter.displayDescription.isNotEmpty
                            ? matter.displayDescription
                            : (matter.isAvailable
                                ? tr('View related legal sections')
                                : tr('Content coming soon — not yet verified')),
                        onTap: () {
                          if (!matter.isAvailable) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('"${matter.displayName}" ${tr("content is coming soon — not yet verified.")}')),
                            );
                            return;
                          }
                          Navigator.push(context,
                              MaterialPageRoute(builder: (context) => MatterDetailScreen(matter: matter)));
                        },
                      ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: SectionHeading(
              title: _query.isEmpty
                  ? '${tr("Available Provisions")} (${filtered.length})'
                  : '${tr("Sections")} (${filtered.length})',
              icon: Icons.menu_book_rounded,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),
        if (filtered.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                tr('No matching legal sections found.'),
                style: GoogleFonts.inter(color: AppColors.textSecondary),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final section = filtered[index];
                  return LegalSectionCard(
                    section: section,
                    lawShortName: lookup.lawShortNameFor(section),
                    breadcrumb: lookup.breadcrumbFor(section),
                    isBookmarked: _bookmarkedIds.contains(section.id),
                    isFrequentlyViewed:
                        (_viewCounts[section.id] ?? 0) >= ViewCountService.frequentThreshold,
                    accentColor: categoryStyleFor(lookup.categoryNameFor(section)).color,
                    onBookmarkToggle: () => _toggleBookmark(section.id),
                    onTap: () => _openSection(section),
                  );
                },
                childCount: filtered.length,
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }

  Widget _buildResultTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          leading: IconBadge(icon: icon, color: color, size: 40, iconSize: 20),
          title: Text(title, style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
          subtitle: Text(subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          onTap: onTap,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showAppBar) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          title: Text(
            tr(widget.title),
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
        ),
        body: SafeArea(child: _buildContent()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(child: _buildContent()),
    );
  }
}
