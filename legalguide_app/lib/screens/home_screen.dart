import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../localization/app_strings.dart';
import '../models/category.dart';
import '../models/law.dart';
import '../models/legal_matter.dart';
import '../models/legal_section.dart';
import '../repositories/legal_data_repository.dart';
import '../services/auth_service.dart';
import '../services/analytics_service.dart';
import '../services/bookmark_service.dart';
import '../services/connectivity_status_service.dart';
import '../services/legal_content_localization_service.dart';
import '../services/legal_update_service.dart';
import '../services/locale_service.dart';
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
import 'explore_laws_screen.dart';
import 'legal_awareness_screen.dart';
import 'legal_help_screen.dart';
import 'legal_updates_screen.dart';
import 'section_detail_screen.dart';
import 'admin_dashboard_screen.dart';

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
  bool _lastSyncSucceeded = true;
  DateTime? _lastSyncTime;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Start update check in background (non-blocking)
    LegalUpdateService.loadUpdates();
  }

  Future<void> _loadData() async {
    final isOnline = ConnectivityStatusService.isInternetConnected;
    bool synced = false;
    if (isOnline) {
      synced = await LegalDataRepository.syncAll();
      await LegalUpdateService.loadUpdates(forceSync: true);
    } else {
      await LegalUpdateService.loadUpdates(forceSync: false);
    }

    final results = await Future.wait([
      LegalDataRepository.hasSyncedBefore(),
      LegalDataRepository.loadCategories(),
      LegalDataRepository.loadLaws(),
      LegalDataRepository.loadSections(),
      LegalDataRepository.loadMatters(),
      BookmarkService.getBookmarkedIds(),
      ViewCountService.getAllCounts(),
      SearchHistoryService.getTopQueries(),
      LegalDataRepository.lastSyncTime(),
    ]);
    final hasSyncedBefore = results[0] as bool;
    final categories = results[1] as List<Category>;
    final laws = results[2] as List<Law>;
    final sections = results[3] as List<LegalSection>;
    final matters = results[4] as List<LegalMatter>;
    final bookmarks = results[5] as Set<int>;
    final counts = results[6] as Map<int, int>;
    final topSearches = results[7] as List<String>;
    final lastSyncTime = results[8] as DateTime?;

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
      _lastSyncSucceeded = synced;
      _categories = categories;
      _frequentSections = topFrequent;
      _commonlyReferenced = topCommon;
      _popularSearches = topSearches.isNotEmpty
          ? topSearches.toSet().toList()
          : LegalContentLocalizationService.popularSearches.map((e) => e.id).toList();
      _bookmarkedIds = bookmarks;
      _lookup = SectionLookup(laws, categories);
      _lastSyncTime = lastSyncTime;
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
    AnalyticsService.trackSearch(query);
    AnalyticsService.trackFeature('law_search');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExploreLawsScreen(initialQuery: query, showAppBar: true),
      ),
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return tr('Not available');
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year.toString();
    return '$day/$month/$year';
  }

  /// User-friendly Legal Updates card (shown to ALL users, including admin).
  /// Admin-specific "Verified Legal Database" management is in Admin Dashboard only.

  Widget _buildLegalUpdatesBanner() {
    return ValueListenableBuilder<int>(
      valueListenable: LegalUpdateService.unreadCount,
      builder: (context, unreadCount, _) {
        return ValueListenableBuilder<NetworkStatus>(
          valueListenable: ConnectivityStatusService.status,
          builder: (context, networkStatus, _) {
            final syncDateStr = _formatDate(_lastSyncTime);
            final bool isOffline = networkStatus == NetworkStatus.offline;
            final bool hasUpdates = unreadCount > 0;
            final bool syncFailed = !_lastSyncSucceeded;

            final Color bgColor;
            final Color borderColor;
            final Color accentColor;
            final IconData iconData;
            final String titleText;
            final String subtitleText;
            final Widget trailingWidget;

            if (isOffline || (syncFailed && !hasUpdates)) {
              // State D: Offline or failed synchronization
              bgColor = AppColors.warning.withValues(alpha: 0.10);
              borderColor = AppColors.warning.withValues(alpha: 0.4);
              accentColor = AppColors.warning;
              iconData = Icons.cloud_off_rounded;
              titleText = tr('Offline — Showing Saved Legal Information');
              subtitleText = '${tr("Last synchronized")}: $syncDateStr';
              trailingWidget = Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  tr('View Updates'),
                  style: GoogleFonts.inter(
                    color: accentColor,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            } else if (syncFailed && hasUpdates) {
              // State C: A newer published version is known but synchronization has not succeeded
              bgColor = const Color(0xFFF97316).withValues(alpha: 0.10);
              borderColor = const Color(0xFFF97316).withValues(alpha: 0.4);
              accentColor = const Color(0xFFEA580C);
              iconData = Icons.sync_problem_rounded;
              titleText = tr('Update Available — Sync Required');
              subtitleText = '${tr("Last synchronized")}: $syncDateStr';
              trailingWidget = Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  tr('Sync Now'),
                  style: GoogleFonts.inter(
                    color: accentColor,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            } else if (hasUpdates) {
              // State B: A published update is available
              bgColor = AppColors.accent.withValues(alpha: 0.08);
              borderColor = AppColors.accent.withValues(alpha: 0.35);
              accentColor = AppColors.accent;
              iconData = Icons.campaign_rounded;
              titleText = tr('New Legal Information Available');
              subtitleText = '$unreadCount ${tr("new verified updates available")}';
              trailingWidget = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      unreadCount > 1 ? '$unreadCount NEW' : 'NEW',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      tr('View Updates'),
                      style: GoogleFonts.inter(
                        color: accentColor,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              );
            } else {
              // State A: No unseen published updates
              bgColor = AppColors.success.withValues(alpha: 0.07);
              borderColor = AppColors.success.withValues(alpha: 0.3);
              accentColor = AppColors.success;
              iconData = Icons.check_circle_rounded;
              titleText = tr('Legal Information Up to Date');
              subtitleText = '${tr("Last synchronized")}: $syncDateStr';
              trailingWidget = Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  tr('View Updates'),
                  style: GoogleFonts.inter(
                    color: accentColor,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }

            return InkWell(
              onTap: () async {
                if (syncFailed && hasUpdates && !isOffline) {
                  await _loadData();
                } else {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LegalUpdatesScreen()),
                  );
                  if (mounted) {
                    await LegalUpdateService.loadUpdates();
                    await _loadData();
                  }
                }
              },
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Icon(iconData, color: accentColor, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titleText,
                            style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            subtitleText,
                            style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    trailingWidget,
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _quickAccessCard(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        height: 98,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconBadge(icon: icon, color: color, size: 36, iconSize: 18),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              softWrap: true,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legalAwarenessParentCard() {
    return Semantics(
      label: '${tr("Legal Awareness")}, ${tr("Rights, rules & citizen protections")}',
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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LegalAwarenessScreen()),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.18),
                          width: 1,
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.campaign_rounded, color: Color(0xFF6366F1), size: 24),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            tr('Legal Awareness'),
                            maxLines: 2,
                            softWrap: true,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: const Color(0xFF0F172A),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tr('Rights, rules & citizen protections'),
                            maxLines: 2,
                            softWrap: true,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: const Color(0xFF64748B),
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF94A3B8),
                      size: 24,
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
              softWrap: true,
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
    return ValueListenableBuilder<String>(
      valueListenable: LocaleService.language,
      builder: (context, currentLang, _) {
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
                          ValueListenableBuilder<String?>(
                            valueListenable: AuthService.currentUsername,
                            builder: (context, username, _) {
                              return ValueListenableBuilder<String?>(
                                valueListenable: AuthService.currentRole,
                                builder: (context, role, _) {
                                  if (!AuthService.isAdmin) return const SizedBox.shrink();
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const AdminDashboardScreen(),
                                          ),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.22),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.2),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.insights_rounded, color: Colors.white, size: 15),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Admin',
                                              style: GoogleFonts.inter(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildLegalUpdatesBanner(),
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
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isTablet = constraints.maxWidth >= 580;
                        if (isTablet) {
                          return Row(
                            children: [
                              Expanded(
                                child: _quickAccessCard(tr('Search Laws'), Icons.search_rounded, AppColors.accent, widget.onOpenExplore),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _quickAccessCard(tr('Ask AI'), Icons.chat_bubble_rounded, const Color(0xFFA78BFA), widget.onOpenAssistant),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _quickAccessCard(tr('Arrest &\nDetention'), Icons.local_police_rounded, const Color(0xFFF59E0B), () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ArrestDetentionScreen()));
                                }),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _quickAccessCard(tr('Legal\nDocuments'), Icons.description_rounded, const Color(0xFF14B8A6), () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => const DocumentsScreen()));
                                }),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _quickAccessCard(tr('Need Legal\nHelp'), Icons.support_agent_rounded, const Color(0xFFF43F5E), () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => const LegalHelpScreen()));
                                }),
                              ),
                            ],
                          );
                        }

                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _quickAccessCard(tr('Search Laws'), Icons.search_rounded, AppColors.accent, widget.onOpenExplore),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _quickAccessCard(tr('Ask AI'), Icons.chat_bubble_rounded, const Color(0xFFA78BFA), widget.onOpenAssistant),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _quickAccessCard(tr('Arrest &\nDetention'), Icons.local_police_rounded, const Color(0xFFF59E0B), () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ArrestDetentionScreen()));
                                  }),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _quickAccessCard(tr('Legal\nDocuments'), Icons.description_rounded, const Color(0xFF14B8A6), () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => const DocumentsScreen()));
                                  }),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _quickAccessCard(tr('Need Legal\nHelp'), Icons.support_agent_rounded, const Color(0xFFF43F5E), () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => const LegalHelpScreen()));
                                  }),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 26),
                    SectionHeading(title: tr('Legal Awareness'), icon: Icons.campaign_rounded),
                    const SizedBox(height: 12),
                    _legalAwarenessParentCard(),
                    const SizedBox(height: 16),
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
                          for (final query in _popularSearches) ...[
                            Builder(
                              builder: (context) {
                                final item = LegalContentLocalizationService.getLocalizedSearchTerm(query);
                                final label = item != null ? item.displayLabel : tr(query);
                                final sq = item != null ? item.searchQuery : query;
                                return ActionChip(
                                  avatar: const Icon(Icons.search_rounded, size: 14, color: AppColors.accent),
                                  label: Text(label),
                                  backgroundColor: AppColors.surface,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.pill),
                                    side: const BorderSide(color: AppColors.border),
                                  ),
                                  labelStyle: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 12),
                                  onPressed: () => _openSearchSuggestion(sq),
                                );
                              },
                            ),
                          ],
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
      },
    );
  }
}
