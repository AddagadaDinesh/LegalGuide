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
import 'saved_screen.dart';
import '../services/auth_service.dart';
import '../services/bookmark_service.dart';
import '../services/connectivity_status_service.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  final ValueNotifier<int> _bookmarkVersion = ValueNotifier<int>(0);
  int _savedCount = 0;
  String _language = 'English';

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
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF334155),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              _moreTile(sheetContext, Icons.shield_outlined, 'Arrest & Detention',
                  const ArrestDetentionScreen()),
              _moreTile(sheetContext, Icons.description_outlined, 'Documents',
                  const DocumentsScreen()),
              _moreTile(sheetContext, Icons.support_agent_rounded, 'Legal Help',
                  const LegalHelpScreen()),
              _moreTile(sheetContext, Icons.info_outline_rounded, 'About', const AboutScreen()),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _moreTile(BuildContext sheetContext, IconData icon, String label, Widget destination) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF6366F1)),
      title: Text(label, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFF64748B)),
      onTap: () {
        Navigator.pop(sheetContext);
        Navigator.push(context, MaterialPageRoute(builder: (context) => destination));
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
            backgroundColor: const Color(0xFF1E293B),
            title: Text('Log in', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
            content: Text(
              "An account is only needed for the AI Assistant's online mode. Browsing and searching legal content never requires one.",
              style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF94A3B8))),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                },
                child: Text('Log in', style: GoogleFonts.inter(color: const Color(0xFF6366F1), fontWeight: FontWeight.w600)),
              ),
            ],
          );
        }
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: Text('Account', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Text('Logged in as $username', style: GoogleFonts.inter(color: const Color(0xFF94A3B8))),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Close', style: GoogleFonts.inter(color: const Color(0xFF94A3B8))),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await AuthService.logout();
              },
              child: Text('Log out', style: GoogleFonts.inter(color: const Color(0xFFF87171), fontWeight: FontWeight.w600)),
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
          backgroundColor: const Color(0xFF1E293B),
          title: Text('Language', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('English', style: GoogleFonts.inter(color: Colors.white)),
                trailing: _language == 'English'
                    ? const Icon(Icons.check_circle, color: Color(0xFF6366F1))
                    : null,
                onTap: () {
                  setState(() => _language = 'English');
                  Navigator.pop(dialogContext);
                },
              ),
              ListTile(
                enabled: false,
                title: Text('Hindi — Coming soon', style: GoogleFonts.inter(color: const Color(0xFF64748B))),
              ),
              ListTile(
                enabled: false,
                title: Text('Other languages — Coming soon',
                    style: GoogleFonts.inter(color: const Color(0xFF64748B))),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF1E293B),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: ConnectivityStatusService.isOnline,
            builder: (context, isOnline, _) {
              return Text(
                isOnline ? '🟢 Online' : '🟠 Offline – Using LegalGuide Knowledge',
                style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600),
              );
            },
          ),
          Row(
            children: [
              InkWell(
                onTap: _showAccountSheet,
                child: ValueListenableBuilder<String?>(
                  valueListenable: AuthService.currentUsername,
                  builder: (context, username, _) {
                    return Icon(
                      username != null ? Icons.account_circle_rounded : Icons.account_circle_outlined,
                      color: const Color(0xFF94A3B8),
                      size: 18,
                    );
                  },
                ),
              ),
              const SizedBox(width: 14),
              InkWell(
                onTap: _showLanguageDialog,
                child: Row(
                  children: [
                    const Icon(Icons.language_rounded, color: Color(0xFF94A3B8), size: 16),
                    const SizedBox(width: 4),
                    Text(_language, style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Column(
        children: [
          SafeArea(bottom: false, child: _buildStatusStrip()),
          Expanded(
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
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6366F1),
        onPressed: () => showAssistantPanel(context),
        child: const Icon(Icons.chat_bubble_rounded, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1E293B),
        selectedItemColor: const Color(0xFF6366F1),
        unselectedItemColor: const Color(0xFF64748B),
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 3) {
            _showMoreSheet();
            return;
          }
          _openTab(index);
        },
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          const BottomNavigationBarItem(icon: Icon(Icons.travel_explore_rounded), label: 'Explore'),
          BottomNavigationBarItem(
            icon: Badge(
              label: Text('$_savedCount'),
              isLabelVisible: _savedCount > 0,
              backgroundColor: const Color(0xFFF43F5E),
              child: const Icon(Icons.bookmark_rounded),
            ),
            label: 'Saved',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.more_horiz_rounded), label: 'More'),
        ],
      ),
    );
  }
}
