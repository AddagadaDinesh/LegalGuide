import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/legal_awareness_data.dart';
import '../localization/app_strings.dart';
import '../models/legal_awareness_item.dart';
import '../services/analytics_service.dart';
import '../services/locale_service.dart';
import '../theme/app_theme.dart';

/// Dedicated parent screen for practical everyday legal topics and citizen awareness.
///
/// Dynamically renders all enabled LegalAwarenessItem entries registered in
/// [LegalAwarenessData.activeItems] in an ordered, responsive, classic card layout.
class LegalAwarenessScreen extends StatefulWidget {
  const LegalAwarenessScreen({super.key});

  @override
  State<LegalAwarenessScreen> createState() => _LegalAwarenessScreenState();
}

class _LegalAwarenessScreenState extends State<LegalAwarenessScreen> {
  @override
  void initState() {
    super.initState();
    AnalyticsService.trackFeature('legal_awareness');
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LocaleService.language,
      builder: (context, currentLang, _) {
        final items = LegalAwarenessData.activeItems;

        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            scrolledUnderElevation: 1,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: tr('Back'),
            ),
            title: Text(
              tr('Legal Awareness'),
              style: GoogleFonts.outfit(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            centerTitle: false,
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              children: [
                // Top Header Description
                Padding(
                  padding: const EdgeInsets.only(bottom: 20, left: 2, right: 2),
                  child: Text(
                    tr('Explore important rights, rules and legal protections for everyday situations.'),
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                ),

                // Dynamic Categories List
                if (items.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 44, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          Text(
                            tr('No legal awareness categories available.'),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  for (final item in items) ...[
                    _buildCategoryCard(item),
                    const SizedBox(height: 14),
                  ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryCard(LegalAwarenessItem item) {
    return Semantics(
      label: '${tr(item.title)}, ${tr(item.description)}',
      button: true,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.035),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                AnalyticsService.trackFeature('awareness_${item.id}');
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: item.screenBuilder),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icon Container
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: item.accentColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: item.accentColor.withValues(alpha: 0.18),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Icon(item.icon, color: item.accentColor, size: 24),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Title & Description
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  tr(item.title),
                                  maxLines: 2,
                                  softWrap: true,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF0F172A),
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w700,
                                    height: 1.25,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                              if (item.badge != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: item.accentColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: item.accentColor.withValues(alpha: 0.3),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    item.badge!,
                                    style: GoogleFonts.inter(
                                      color: item.accentColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            tr(item.description),
                            maxLines: 3,
                            softWrap: true,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: const Color(0xFF64748B),
                              fontSize: 13,
                              height: 1.38,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Chevron Indicator
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF94A3B8),
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
