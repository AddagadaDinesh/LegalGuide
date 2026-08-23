import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/legal_section.dart';
import '../repositories/legal_data_repository.dart';
import '../services/bookmark_service.dart';
import '../services/view_count_service.dart';

class SectionDetailScreen extends StatefulWidget {
  final LegalSection section;

  const SectionDetailScreen({super.key, required this.section});

  @override
  State<SectionDetailScreen> createState() => _SectionDetailScreenState();
}

class _SectionDetailScreenState extends State<SectionDetailScreen> {
  bool _isBookmarked = false;
  List<LegalSection> _relatedSections = [];

  LegalSection get section => widget.section;

  @override
  void initState() {
    super.initState();
    ViewCountService.recordView(section.id);
    BookmarkService.isBookmarked(section.id).then((value) {
      if (mounted) setState(() => _isBookmarked = value);
    });
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

  Future<void> _toggleBookmark() async {
    await BookmarkService.toggle(section.id);
    final value = await BookmarkService.isBookmarked(section.id);
    if (mounted) setState(() => _isBookmarked = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Text(
          section.sectionNumber,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: const Color(0xFF6366F1),
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
            // Title Header Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                section.sectionNumber.toUpperCase(),
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.1,
                ),
              ),
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
              section.title,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 24),

            // Simple Explanation Card (Highlighted)
            _buildHighlightBox(
              title: 'Key Takeaway (Plain Explanation)',
              icon: Icons.lightbulb_outline,
              content: section.simpleExplanation,
              gradient: const LinearGradient(
                colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
              ),
              borderColor: const Color(0xFF6366F1),
            ),
            const SizedBox(height: 16),

            // Purpose & Scope
            if (section.purpose.isNotEmpty)
              _buildDetailBox(
                title: 'Purpose & Legal Context',
                icon: Icons.track_changes_outlined,
                content: section.purpose,
                accentColor: Colors.cyanAccent,
              ),
            if (section.purpose.isNotEmpty) const SizedBox(height: 16),

            // Key Elements
            if (section.keyElementsList.isNotEmpty)
              _buildBulletBox(
                title: 'Key Elements',
                icon: Icons.checklist_rounded,
                items: section.keyElementsList,
                accentColor: const Color(0xFF38BDF8),
              ),
            if (section.keyElementsList.isNotEmpty) const SizedBox(height: 16),

            // Punishment / Penalties
            if (section.punishment.isNotEmpty)
              _buildDetailBox(
                title: 'Punishment & Penalties',
                icon: Icons.gavel_rounded,
                content: section.punishment,
                accentColor: const Color(0xFFF43F5E),
              ),
            if (section.punishment.isNotEmpty) const SizedBox(height: 16),

            // What Information May Matter
            if (section.relevantInformationList.isNotEmpty)
              _buildBulletBox(
                title: 'What Information May Matter',
                icon: Icons.fact_check_outlined,
                items: section.relevantInformationList,
                accentColor: const Color(0xFFFBBF24),
              ),
            if (section.relevantInformationList.isNotEmpty) const SizedBox(height: 16),

            // Relevant Documents
            if (section.relevantDocuments.isNotEmpty)
              _buildDetailBox(
                title: 'Required / Relevant Documents',
                icon: Icons.folder_copy_outlined,
                content: section.relevantDocuments,
                accentColor: const Color(0xFF10B981),
              ),
            if (section.relevantDocuments.isNotEmpty) const SizedBox(height: 16),

            // Official Legal Text
            _buildDetailBox(
              title: 'Official Statutory Legal Text',
              icon: Icons.menu_book_rounded,
              content: section.legalText,
              accentColor: const Color(0xFFA855F7),
            ),
            const SizedBox(height: 24),

            // Related Legal Provisions
            if (_relatedSections.isNotEmpty) ...[
              Text(
                'Related Legal Provisions',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 10),
              for (final related in _relatedSections)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
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
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF334155)),
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
                                    color: const Color(0xFF6366F1),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  related.title,
                                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Color(0xFF64748B)),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
            ],

            // Source & Verification Footer
            if (section.source.isNotEmpty || section.lastVerified != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withAlpha(150),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_outlined,
                        color: Color(0xFF10B981), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Verified from ${section.source.isEmpty ? "Official Gazette" : section.source}'
                        '${section.lastVerified != null ? " • Last updated ${section.lastVerified}" : ""}',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF94A3B8),
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

  Widget _buildHighlightBox({
    required String title,
    required IconData icon,
    required String content,
    required Gradient gradient,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withAlpha(120), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: borderColor.withAlpha(40),
            blurRadius: 16,
            spreadRadius: -2,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.amberAccent, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  color: Colors.amberAccent,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: GoogleFonts.inter(
              color: Colors.white,
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
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
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
                        color: const Color(0xFFCBD5E1),
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
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: GoogleFonts.inter(
              color: const Color(0xFFCBD5E1),
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
