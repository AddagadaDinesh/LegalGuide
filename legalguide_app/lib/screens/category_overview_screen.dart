import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/category.dart';
import '../models/legal_matter.dart';
import '../repositories/legal_data_repository.dart';
import 'law_list_screen.dart';
import 'matter_detail_screen.dart';

class CategoryOverviewScreen extends StatefulWidget {
  final Category category;

  const CategoryOverviewScreen({super.key, required this.category});

  @override
  State<CategoryOverviewScreen> createState() => _CategoryOverviewScreenState();
}

class _CategoryOverviewScreenState extends State<CategoryOverviewScreen> {
  List<LegalMatter> _matters = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMatters();
  }

  Future<void> _loadMatters() async {
    final matters = await LegalDataRepository.loadMatters(categoryId: widget.category.id);
    if (!mounted) return;
    setState(() {
      _matters = matters;
      _loading = false;
    });
  }

  void _openMatter(LegalMatter matter) {
    if (!matter.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${matter.name}" content is coming soon — not yet verified.')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MatterDetailScreen(matter: matter)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E293B),
          elevation: 0,
          title: Text(widget.category.name,
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
          bottom: TabBar(
            indicatorColor: const Color(0xFF6366F1),
            labelColor: Colors.white,
            unselectedLabelColor: const Color(0xFF94A3B8),
            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
            tabs: const [
              Tab(text: 'Topics'),
              Tab(text: 'Laws & Sections'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                : _buildTopics(),
            LawListScreen(category: widget.category, embedded: true),
          ],
        ),
      ),
    );
  }

  Widget _buildTopics() {
    if (_matters.isEmpty) {
      return Center(
        child: Text('No topics available for this category yet.',
            style: GoogleFonts.inter(color: Colors.white70)),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _matters.length,
      itemBuilder: (context, index) {
        final matter = _matters[index];
        final available = matter.isAvailable;
        return InkWell(
          onTap: () => _openMatter(matter),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: available ? const Color(0xFF1E293B) : const Color(0xFF1E293B).withAlpha(120),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  available ? Icons.topic_outlined : Icons.hourglass_empty_rounded,
                  color: available ? const Color(0xFF6366F1) : const Color(0xFF64748B),
                  size: 22,
                ),
                Text(
                  matter.name,
                  style: GoogleFonts.inter(
                    color: available ? Colors.white : const Color(0xFF94A3B8),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (!available)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF334155),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Coming soon',
                      style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 10),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
