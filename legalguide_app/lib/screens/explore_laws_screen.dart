import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/category.dart';
import '../models/legal_matter.dart';
import '../models/legal_section.dart';
import '../repositories/legal_data_repository.dart';
import '../services/bookmark_service.dart';
import '../services/search_history_service.dart';
import '../services/view_count_service.dart';
import '../utils/section_lookup.dart';
import '../widgets/legal_section_card.dart';
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
    SearchHistoryService.recordQuery(value);
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
          child: CircularProgressIndicator(color: Color(0xFF6366F1)),
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
                      widget.title,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                TextField(
                  controller: _searchController,
                  style: GoogleFonts.inter(color: Colors.white),
                  onChanged: _onQueryChanged,
                  decoration: InputDecoration(
                    hintText: 'Search laws, section numbers, topics...',
                    hintStyle: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF6366F1)),
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF334155)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF334155)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
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
                          label: const Text('All'),
                          selected: _selectedCategoryId == null,
                          onSelected: (_) => setState(() => _selectedCategoryId = null),
                          selectedColor: const Color(0xFF6366F1),
                          backgroundColor: const Color(0xFF1E293B),
                          labelStyle: GoogleFonts.inter(color: Colors.white, fontSize: 12),
                        ),
                        const SizedBox(width: 8),
                        for (final category in _categories) ...[
                          ChoiceChip(
                            label: Text(category.name),
                            selected: _selectedCategoryId == category.id,
                            onSelected: (_) => setState(() => _selectedCategoryId = category.id),
                            selectedColor: const Color(0xFF6366F1),
                            backgroundColor: const Color(0xFF1E293B),
                            labelStyle: GoogleFonts.inter(color: Colors.white, fontSize: 12),
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
                    Text('Categories (${_matchedCategories.length})',
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    for (final category in _matchedCategories)
                      _buildResultTile(
                        icon: Icons.category_outlined,
                        title: category.name,
                        subtitle: category.description,
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (context) => CategoryOverviewScreen(category: category))),
                      ),
                    const SizedBox(height: 12),
                  ],
                  if (_matchedMatters.isNotEmpty) ...[
                    Text('Topics (${_matchedMatters.length})',
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    for (final matter in _matchedMatters)
                      _buildResultTile(
                        icon: matter.isAvailable ? Icons.topic_outlined : Icons.hourglass_empty_rounded,
                        title: matter.name,
                        subtitle: matter.description.isNotEmpty
                            ? matter.description
                            : (matter.isAvailable
                                ? 'View related legal sections'
                                : 'Content coming soon — not yet verified'),
                        onTap: () {
                          if (!matter.isAvailable) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('"${matter.name}" content is coming soon — not yet verified.')),
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
            child: Text(
              _query.isEmpty ? 'Available Provisions (${filtered.length})' : 'Sections (${filtered.length})',
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 10)),
        if (filtered.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'No matching legal sections found.',
                style: GoogleFonts.inter(color: Colors.white70),
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
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          leading: Icon(icon, color: const Color(0xFF6366F1)),
          title: Text(title, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
          subtitle: Text(subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 12)),
          trailing: const Icon(Icons.chevron_right, color: Color(0xFF64748B)),
          onTap: onTap,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showAppBar) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E293B),
          elevation: 0,
          title: Text(
            widget.title,
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        body: SafeArea(child: _buildContent()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(child: _buildContent()),
    );
  }
}
