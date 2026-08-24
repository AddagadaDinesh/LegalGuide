import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/legal_section.dart';
import '../theme/app_theme.dart';

class LegalSectionCard extends StatelessWidget {
  final LegalSection section;
  final String lawShortName;
  final String breadcrumb;
  final bool isBookmarked;
  final bool isFrequentlyViewed;
  final VoidCallback onBookmarkToggle;
  final VoidCallback onTap;
  final Color accentColor;

  const LegalSectionCard({
    super.key,
    required this.section,
    required this.lawShortName,
    required this.breadcrumb,
    required this.isBookmarked,
    required this.isFrequentlyViewed,
    required this.onBookmarkToggle,
    required this.onTap,
    this.accentColor = AppColors.accent,
  });

  Widget _tag(String text, {Color? bg, Color? fg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg ?? AppColors.border,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: fg ?? AppColors.textSecondary,
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
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: accentColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (lawShortName.isNotEmpty) ...[
                              _tag(lawShortName, bg: accentColor.withValues(alpha: 0.18), fg: accentColor),
                              const SizedBox(width: 6),
                            ],
                            _tag(section.sectionNumber),
                            if (section.badge.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              _tag(section.badge, bg: const Color(0xFF064E3B), fg: const Color(0xFF6EE7B7)),
                            ],
                            if (isFrequentlyViewed) ...[
                              const SizedBox(width: 6),
                              _tag('Frequent', bg: const Color(0xFF854D0E), fg: const Color(0xFFFDE68A)),
                            ],
                            const Spacer(),
                            IconButton(
                              icon: Icon(
                                isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                color: AppColors.accent,
                                size: 20,
                              ),
                              onPressed: onBookmarkToggle,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            ),
                          ],
                        ),
                        const SizedBox(height: 9),
                        Text(
                          section.title,
                          style: GoogleFonts.outfit(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            height: 1.25,
                          ),
                        ),
                        if (breadcrumb.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            breadcrumb,
                            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                        const SizedBox(height: 9),
                        Text(
                          'IN SIMPLE WORDS',
                          style: GoogleFonts.inter(
                            color: accentColor,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          section.simpleExplanation,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
