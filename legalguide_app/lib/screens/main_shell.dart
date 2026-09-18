import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'about_screen.dart';
import 'arrest_detention_screen.dart';
import 'assistant_chat_screen.dart';
import 'documents_screen.dart';
import 'explore_laws_screen.dart';
import 'home_screen.dart';
import 'legal_help_screen.dart';
import 'login_screen.dart';
import 'railway_rules_screen.dart';
import 'saved_screen.dart';
import '../localization/app_strings.dart';
import '../services/auth_service.dart';
import '../services/bookmark_service.dart';
import '../services/connectivity_status_service.dart';
import '../services/locale_service.dart';
import '../theme/app_theme.dart';
import '../widgets/icon_badge.dart';
import '../widgets/watermark_background.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  final ValueNotifier<int> _bookmarkVersion = ValueNotifier<int>(0);
  int _savedCount = 0;

  @override
  void initState() {
    super.initState();
    _bookmarkVersion.addListener(_refreshSavedCount);
    _refreshSavedCount();
    ConnectivityStatusService.start();
  }

  @override
  void dispose() {
    _bookmarkVersion.removeListener(_refreshSavedCount);
    _bookmarkVersion.dispose();
    ConnectivityStatusService.stop();
    super.dispose();
  }

  Future<void> _refreshSavedCount() async {
    final count = await BookmarkService.count();
    if (mounted) setState(() => _savedCount = count);
  }

  void _openTab(int index) => setState(() => _currentIndex = index);

  void _showMoreSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              _moreTile(
                sheetContext,
                Icons.train_rounded,
                const Color(0xFF0284C7),
                tr('Railway Rules & Fines'),
                const RailwayRulesScreen(),
              ),
              _moreTile(
                sheetContext,
                Icons.local_police_rounded,
                const Color(0xFFF59E0B),
                tr('Arrest & Detention'),
                const ArrestDetentionScreen(),
              ),
              _moreTile(
                sheetContext,
                Icons.description_rounded,
                const Color(0xFF14B8A6),
                tr('Documents'),
                const DocumentsScreen(),
              ),
              _moreTile(
                sheetContext,
                Icons.support_agent_rounded,
                const Color(0xFFF43F5E),
                tr('Legal Help'),
                const LegalHelpScreen(),
              ),
              _moreTile(
                sheetContext,
                Icons.info_rounded,
                AppColors.accent,
                tr('About'),
                const AboutScreen(),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      );
    },
  );
  }

  Widget _moreTile(
    BuildContext sheetContext,
    IconData icon,
    Color color,
    String label,
    Widget destination,
  ) {
    return ListTile(
      leading: IconBadge(icon: icon, color: color, size: 40, iconSize: 20),
      title: Text(
        label,
        style: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textMuted,
      ),
      onTap: () {
        Navigator.pop(sheetContext);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => destination),
        );
      },
    );
  }

  void _showAccountSheet() {
    final username = AuthService.currentUsername.value;
    showDialog(
      context: context,
      builder: (dialogContext) {
        if (username == null) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text(
              tr('Log in'),
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              tr("An account is only needed for the AI Assistant's online mode. Browsing and searching legal content never requires one."),
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  tr('Cancel'),
                  style: GoogleFonts.inter(color: AppColors.textSecondary),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                child: Text(
                  tr('Log in'),
                  style: GoogleFonts.inter(
                    color: const Color(0xFF6366F1),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        }
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            tr('Account'),
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            '${tr("Logged in as")} $username',
            style: GoogleFonts.inter(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                tr('Close'),
                style: GoogleFonts.inter(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await AuthService.logout();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      tr('Logged out. You can still browse offline legal content.'),
                    ),
                  ),
                );
              },
              child: Text(
                tr('Log out'),
                style: GoogleFonts.inter(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            tr('Language'),
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: ValueListenableBuilder<String>(
            valueListenable: LocaleService.language,
            builder: (context, currentLang, _) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(
                    tr('English'),
                    style: GoogleFonts.inter(color: AppColors.textPrimary),
                  ),
                  trailing: currentLang == 'en'
                      ? const Icon(Icons.check_circle, color: AppColors.accent)
                      : null,
                  onTap: () async {
                    await LocaleService.setLanguage('en');
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                  },
                ),
                ListTile(
                  title: Text(
                    tr('Telugu'),
                    style: GoogleFonts.inter(color: AppColors.textPrimary),
                  ),
                  trailing: currentLang == 'te'
                      ? const Icon(Icons.check_circle, color: AppColors.accent)
                      : null,
                  onTap: () async {
                    await LocaleService.setLanguage('te');
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                  },
                ),
                ListTile(
                  enabled: false,
                  title: Text(
                    tr('Hindi — Coming soon'),
                    style: GoogleFonts.inter(color: AppColors.textMuted),
                  ),
                ),
                ListTile(
                  enabled: false,
                  title: Text(
                    tr('Other languages — Coming soon'),
                    style: GoogleFonts.inter(color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: ValueListenableBuilder<bool>(
              valueListenable: ConnectivityStatusService.isOnline,
              builder: (context, isOnline, _) {
                final color = isOnline ? AppColors.success : AppColors.warning;
                return InkWell(
                  onTap: isOnline
                      ? null
                      : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AboutScreen(),
                          ),
                        ),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            isOnline
                                ? tr('Online')
                                : tr('Offline · Using LegalGuide Knowledge'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Row(
            children: [
              InkWell(
                onTap: _showAccountSheet,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: ValueListenableBuilder<String?>(
                    valueListenable: AuthService.currentUsername,
                    builder: (context, username, _) {
                      return Icon(
                        username != null
                            ? Icons.account_circle_rounded
                            : Icons.account_circle_outlined,
                        color: AppColors.textSecondary,
                        size: 18,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: _showLanguageDialog,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.language_rounded,
                        color: AppColors.textSecondary,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      ValueListenableBuilder<String>(
                        valueListenable: LocaleService.language,
                        builder: (context, lang, _) => Text(
                          lang == 'te' ? tr('Telugu') : tr('English'),
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
    Widget? badge,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.accent.withValues(alpha: 0.16)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child:
                    badge ??
                    Icon(
                      icon,
                      color: selected ? AppColors.accent : AppColors.textMuted,
                      size: 21,
                    ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: selected ? AppColors.accent : AppColors.textMuted,
                  fontSize: 10.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          SafeArea(bottom: false, child: _buildStatusStrip()),
          Expanded(
            child: WatermarkBackground(
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  HomeScreen(
                    onOpenExplore: () => _openTab(1),
                    onOpenAssistant: () => showAssistantPanel(context),
                    bookmarkVersion: _bookmarkVersion,
                  ),
                  const ExploreLawsScreen(),
                  SavedScreen(bookmarkVersion: _bookmarkVersion),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: AppColors.accentGradient,
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          onPressed: () => showAssistantPanel(context),
          child: const Icon(Icons.chat_bubble_rounded, color: Colors.white),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 70,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              _navItem(
                icon: Icons.home_rounded,
                label: tr('Home'),
                selected: _currentIndex == 0,
                onTap: () => _openTab(0),
              ),
              _navItem(
                icon: Icons.travel_explore_rounded,
                label: tr('Explore'),
                selected: _currentIndex == 1,
                onTap: () => _openTab(1),
              ),
              _navItem(
                icon: Icons.bookmark_rounded,
                label: tr('Saved'),
                selected: _currentIndex == 2,
                onTap: () => _openTab(2),
                badge: Badge(
                  label: Text('$_savedCount'),
                  isLabelVisible: _savedCount > 0,
                  backgroundColor: AppColors.danger,
                  child: Icon(
                    Icons.bookmark_rounded,
                    color: _currentIndex == 2
                        ? AppColors.accent
                        : AppColors.textMuted,
                    size: 22,
                  ),
                ),
              ),
              _navItem(
                icon: Icons.more_horiz_rounded,
                label: tr('More'),
                selected: false,
                onTap: _showMoreSheet,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
