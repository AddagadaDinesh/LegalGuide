import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/legal_section.dart';

class LegalSectionCard extends StatelessWidget {
  final LegalSection section;
  final String lawShortName;
  final String breadcrumb;
  final bool isBookmarked;
  final bool isFrequentlyViewed;
  final VoidCallback onBookmarkToggle;
  final VoidCallback onTap;

  const LegalSectionCard({
    super.key,
    required this.section,
    required this.lawShortName,
    required this.breadcrumb,
    required this.isBookmarked,
    required this.isFrequentlyViewed,
    required this.onBookmarkToggle,
    required this.onTap,
  });

  Widget _tag(String text, {Color? bg, Color? fg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg ?? const Color(0xFF334155),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: fg ?? const Color(0xFFCBD5E1),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (lawShortName.isNotEmpty) ...[
                      _tag(lawShortName, bg: const Color(0xFF312E81), fg: const Color(0xFFC7D2FE)),
                      const SizedBox(width: 6),
                    ],
                    _tag(section.sectionNumber),
                    if (section.badge.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      _tag(section.badge, bg: const Color(0xFF064E3B), fg: const Color(0xFF6EE7B7)),
                    ],
                    if (isFrequentlyViewed) ...[
                      const SizedBox(width: 6),
                      _tag('Frequently viewed', bg: const Color(0xFF854D0E), fg: const Color(0xFFFDE68A)),
                    ],
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                        color: const Color(0xFF6366F1),
                        size: 20,
                      ),
                      onPressed: onBookmarkToggle,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  section.title,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (breadcrumb.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    breadcrumb,
                    style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 12),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'In Simple Words:',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF6366F1),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  section.simpleExplanation,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(color: const Color(0xFFCBD5E1), fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
