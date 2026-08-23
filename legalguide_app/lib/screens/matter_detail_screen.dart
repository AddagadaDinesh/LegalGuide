import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/category.dart';
import '../models/law.dart';
import '../models/legal_matter.dart';
import '../repositories/legal_data_repository.dart';
import '../services/bookmark_service.dart';
import '../services/view_count_service.dart';
import '../utils/section_lookup.dart';
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

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Text(matter.name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
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
                    if (matter.description.isNotEmpty) ...[
                      Text(
                        matter.description,
                        style: GoogleFonts.inter(color: const Color(0xFFCBD5E1), fontSize: 14, height: 1.5),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (sections.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 30.0),
                        child: Column(
                          children: [
                            const Icon(Icons.hourglass_empty_rounded, color: Color(0xFF64748B), size: 36),
                            const SizedBox(height: 12),
                            Text(
                              'Verified legal sections for this topic are not available yet.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(color: const Color(0xFF94A3B8)),
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
