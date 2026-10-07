import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../localization/app_strings.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/backend_config_service.dart';
import '../services/connectivity_status_service.dart';
import '../services/locale_service.dart';
import '../theme/app_theme.dart';
import 'admin_dashboard_screen.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  late final TextEditingController _urlController;
  String? _savedMessage;
  int _tapCount = 0;
  bool _developerMode = false;

  bool get _isAdminUser {
    if (AuthService.isAdmin) return true;
    final user = AuthService.currentUsername.value?.toLowerCase().trim();
    return user == 'dinesh' ||
        user == 'dinesh03' ||
        user == 'admin' ||
        user == 'dinesh_admin';
  }

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: ApiService.baseUrl);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ConnectivityStatusService.checkNow(force: true);
    });
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _saveUrl() async {
    await BackendConfigService.setBaseUrl(_urlController.text);
    setState(() {
      _urlController.text = ApiService.baseUrl;
      _savedMessage = tr('Saved. New requests will use this address.');
    });
  }

  Future<void> _resetUrl() async {
    await BackendConfigService.setBaseUrl('');
    setState(() {
      _urlController.text = ApiService.baseUrl;
      _savedMessage = tr('Reset to default.');
    });
  }

  Future<void> _dialNumber(String number) async {
    final uri = Uri.parse('tel:$number');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LocaleService.language,
      builder: (context, lang, _) {
        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            title: Text(
              tr('About'),
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isAdminUser) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF312E81), Color(0xFF1E1B4B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.6), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                tr('Admin Dashboard'),
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade700,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'ADMIN',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            tr('App usage, active users & feature analytics'),
                            style: GoogleFonts.inter(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: Text(tr('Open'), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
            GestureDetector(
              onTap: () {
                if (!_isAdminUser) return;

                _tapCount++;
                if (_tapCount >= 5) {
                  _tapCount = 0;
                  setState(() => _developerMode = !_developerMode);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _developerMode
                            ? 'Admin mode: Server settings unlocked'
                            : 'Admin settings locked and hidden',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(
                      Icons.gavel_rounded,
                      color: AppColors.accent,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LegalGuide',
                        style: GoogleFonts.outfit(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        tr('Simplified Legal Knowledge & Assistance'),
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              tr(
                'LegalGuide helps you look up Indian laws and legal provisions in plain '
                "language, browse offline once synced, and ask an AI assistant questions — "
                "answered either from what's actually stored in the app (offline) or from a "
                "general AI model when you're online.",
              ),
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.accent.withAlpha(120),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.warning,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        tr('Disclaimer'),
                        style: GoogleFonts.inter(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    tr(
                      'LegalGuide is an educational prototype. Information provided does not '
                      'constitute certified legal advice and may not reflect the most current '
                      'legal developments. Always consult a qualified legal professional for '
                      'advice about your specific situation.',
                    ),
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // System Status & App Specifications Card for regular users
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(8),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr('System & Security Status'),
                            style: GoogleFonts.outfit(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          ValueListenableBuilder<DateTime?>(
                            valueListenable: ConnectivityStatusService.lastChecked,
                            builder: (context, lastTime, _) {
                              if (lastTime == null) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  '${tr('Last checked:')} ${_formatTime(lastTime)}',
                                  style: GoogleFonts.inter(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ValueListenableBuilder<NetworkStatus>(
                            valueListenable: ConnectivityStatusService.status,
                            builder: (context, status, _) {
                              final Color color;
                              final String label;

                              switch (status) {
                                case NetworkStatus.online:
                                  color = AppColors.success;
                                  label = tr('Server Online');
                                  break;
                                case NetworkStatus.serverOnlineDatabaseUnavailable:
                                  color = const Color(0xFFE67E22);
                                  label = tr('Server Online (DB Unavailable)');
                                  break;
                                case NetworkStatus.internetAvailableBackendUnavailable:
                                  color = const Color(0xFFE67E22);
                                  label = tr('Server Unavailable');
                                  break;
                                case NetworkStatus.offline:
                                  color = AppColors.warning;
                                  label = tr('Offline');
                                  break;
                              }

                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withAlpha(30),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      label,
                                      style: GoogleFonts.inter(
                                        color: color,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            color: AppColors.textSecondary,
                            tooltip: tr('Check status now'),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                            onPressed: () => ConnectivityStatusService.checkNow(force: true),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _specRow(Icons.verified_user_rounded, tr('Edition'), 'Citizen Prototype v1.1.0'),
                  _specRow(Icons.auto_awesome_rounded, tr('AI Engine'), tr('Dual-Mode (Cloud + Offline Engine)')),
                  _specRow(Icons.menu_book_rounded, tr('Coverage'), 'BNS, BNSS, BSA (2024), Railways Act, MV Act (2019)'),
                  _specRow(Icons.record_voice_over_rounded, tr('Audio'), tr('Voice Search & TTS Audio Narration')),
                  _specRow(Icons.cloud_sync_rounded, tr('Cloud Sync'), tr('User Bookmarks & Offline-First Cache')),
                  _specRow(Icons.translate_rounded, tr('Languages'), 'English, Telugu (తెలుగు), Hindi (हिन्दी)'),
                  _specRow(Icons.lock_outline_rounded, tr('Privacy'), tr('Zero Search Tracking & Encrypted Auth')),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // What's New in v1.1.0 Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(8),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.new_releases_rounded, color: Color(0xFF6366F1), size: 22),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        tr("What's New in v1.1.0"),
                        style: GoogleFonts.outfit(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _updateItem(
                    Icons.shield_rounded,
                    const Color(0xFFDC2626),
                    tr('Emergency Rights Guide'),
                    tr('Instant citizen protections for police stops, traffic challans, cyber fraud (1930) and women rights.'),
                  ),
                  _updateItem(
                    Icons.traffic_rounded,
                    const Color(0xFFD97706),
                    tr('Traffic Rules & Fines (MV Act)'),
                    tr('Full Motor Vehicles Act penalty table, driver rights, and step-by-step e-challan dispute guide.'),
                  ),
                  _updateItem(
                    Icons.edit_document,
                    const Color(0xFF4F46E5),
                    tr('Interactive Document Generator'),
                    tr('Draft formal Police Complaints, RTI Applications, and Legal Notices with instant copy & export.'),
                  ),
                  _updateItem(
                    Icons.volume_up_rounded,
                    const Color(0xFF0284C7),
                    tr('Audio Narration (TTS) & Voice Search'),
                    tr('Listen aloud to legal sections, railway rules, and emergency guides in your preferred language.'),
                  ),
                  _updateItem(
                    Icons.cloud_sync_rounded,
                    const Color(0xFF10B981),
                    tr('Cloud Bookmark Sync'),
                    tr('Seamlessly sync your saved laws and sections across devices when logged into your account.'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Emergency / Citizen Helplines Section
            Text(
              tr('24/7 Citizen Helplines'),
              style: GoogleFonts.outfit(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              tr('Official government emergency and grievance helplines in India:'),
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            _helplineTile('112', tr('National Emergency (Police, Fire, Medical)'), const Color(0xFFDC2626)),
            _helplineTile('139', tr('RailMadad (Indian Railways Grievance & Security)'), const Color(0xFF0284C7)),
            _helplineTile('1930', tr('National Cyber Crime Financial Helpline'), const Color(0xFF7C3AED)),
            _helplineTile('1091', tr('Women Safety & Emergency Helpline'), const Color(0xFFDB2777)),
            _helplineTile('1915', tr('National Consumer Grievance Helpline'), const Color(0xFFEA580C)),

            // Server Connection - Visible only if Admin is authenticated and unlocked
            if (_isAdminUser && _developerMode) ...[
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.accent, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.admin_panel_settings_rounded,
                          color: AppColors.accent,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          tr('Server Connection (Admin Only)'),
                          style: GoogleFonts.outfit(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tr(
                        'Address the app uses for online features (AI Assistant, syncing content). '
                        "Update this if your LegalGuide server's address changes, e.g. a new tunnel URL.",
                      ),
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _urlController,
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        hintText: 'https://your-tunnel-url.trycloudflare.com/api',
                        hintStyle: GoogleFonts.inter(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                        filled: true,
                        fillColor: AppColors.bg,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.accent,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _saveUrl,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                          ),
                          child: Text(
                            tr('Save'),
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        TextButton(
                          onPressed: _resetUrl,
                          child: Text(
                            tr('Reset to default'),
                            style: GoogleFonts.inter(color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                    if (_savedMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _savedMessage!,
                        style: GoogleFonts.inter(
                          color: AppColors.success,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
            Center(
              child: Text(
                '🇮🇳 Made for Indian Citizens • Legal Literacy Initiative',
                style: GoogleFonts.inter(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
      },
    );
  }

  Widget _specRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.accent),
          const SizedBox(width: 10),
          SizedBox(
            width: 85,
            child: Text(
              title,
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _helplineTile(String number, String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withAlpha(80)),
            ),
            child: Text(
              number,
              style: GoogleFonts.outfit(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.phone_in_talk_rounded, size: 18),
            color: color,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => _dialNumber(number),
          ),
        ],
      ),
    );
  }

  Widget _updateItem(IconData icon, Color color, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
