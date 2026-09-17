import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../localization/app_strings.dart';
import '../models/category.dart';
import '../models/legal_matter.dart';
import '../repositories/legal_data_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/icon_badge.dart';
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
        SnackBar(content: Text('"${matter.displayName}" ${tr("content is coming soon — not yet verified.")}')),
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
    final style = categoryStyleFor(widget.category.name);
    final populated = _matters.where((m) => m.isAvailable).length;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          title: Text(widget.category.displayName,
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          bottom: TabBar(
            indicatorColor: style.color,
            indicatorWeight: 3,
            labelColor: AppColors.textPrimary,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
            tabs: [
              Tab(text: tr('Topics')),
              Tab(text: tr('Laws & Sections')),
            ],
          ),
        ),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              color: AppColors.surface,
              child: Row(
                children: [
                  IconBadge(icon: style.icon, color: style.color, size: 48, iconSize: 24),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.category.displayDescription.isNotEmpty
                              ? widget.category.displayDescription
                              : widget.category.displayName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12.5, height: 1.4),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${_matters.length} ${tr("topics")} · $populated ${tr("with legal sections")}',
                          style: GoogleFonts.inter(color: style.color, fontSize: 11.5, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _loading
                      ? Center(child: CircularProgressIndicator(color: style.color))
                      : _buildTopics(style),
                  LawListScreen(category: widget.category, embedded: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopics(CategoryStyle style) {
    if (_matters.isEmpty) {
      return Center(
        child: Text(tr('No topics available for this category yet.'),
            style: GoogleFonts.inter(color: AppColors.textSecondary)),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.02,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _matters.length,
      itemBuilder: (context, index) {
        final matter = _matters[index];
        final available = matter.isAvailable;
        return InkWell(
          onTap: () => _openMatter(matter),
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: available ? style.color.withValues(alpha: 0.35) : AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconBadge(
                  icon: available ? Icons.topic_rounded : Icons.hourglass_empty_rounded,
                  color: available ? style.color : AppColors.textMuted,
                  size: 38,
                  iconSize: 18,
                ),
                Text(
                  matter.displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: available ? AppColors.textPrimary : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
                if (available)
                  Text(
                    '${matter.relatedSectionIds.length} ${tr(matter.relatedSectionIds.length == 1 ? "section" : "sections")}',
                    style: GoogleFonts.inter(color: style.color, fontSize: 10.5, fontWeight: FontWeight.w600),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tr('Coming soon'),
                      style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 10),
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
