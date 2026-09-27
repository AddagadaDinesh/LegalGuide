import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../localization/app_strings.dart';
import '../services/locale_service.dart';
import '../theme/app_theme.dart';
import 'emergency_guide_screen.dart';
import 'railway_rules_screen.dart';

/// Dedicated Hub housing both Emergency Rights and Indian Railway Rules.
class CitizenRightsTravelScreen extends StatefulWidget {
  final int initialTab;

  const CitizenRightsTravelScreen({
    super.key,
    this.initialTab = 0,
  });

  @override
  State<CitizenRightsTravelScreen> createState() => _CitizenRightsTravelScreenState();
}

class _CitizenRightsTravelScreenState extends State<CitizenRightsTravelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _makeCall(String number) async {
    final uri = Uri.parse('tel:$number');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  void _showHelplinesSheet() {
    final isTe = LocaleService.isTelugu;
    final isHi = LocaleService.isHindi;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.phone_in_talk_rounded, color: Colors.red, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr('Emergency Helplines'),
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            isTe
                                ? 'తక్షణ అత్యవసర సహాయం కోసం నంబర్‌పై నొక్కండి'
                                : (isHi
                                    ? 'तत्काल सहायता के लिए नंबर पर टैप करें'
                                    : 'Tap any number to dial immediately'),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _helplineTile(
                  number: '112',
                  title: tr('National Emergency Number'),
                  subtitle: isTe ? 'పోలీస్, అగ్నిమాపక & అంబులెన్స్' : (isHi ? 'पुलिस, अग्निशमन और एम्बुलेंस' : 'Police, Fire & Medical'),
                  color: const Color(0xFFDC2626),
                  icon: Icons.local_police_rounded,
                ),
                _helplineTile(
                  number: '139',
                  title: tr('Indian Railways (RailMadad)'),
                  subtitle: isTe ? 'రైల్వే రక్షణ, ఫిర్యాదులు & సమాచారం' : (isHi ? 'सुरक्षा, शिकायत और ट्रेन स्थिति' : 'Security, Medical & Train Help'),
                  color: const Color(0xFF0284C7),
                  icon: Icons.train_rounded,
                ),
                _helplineTile(
                  number: '1930',
                  title: tr('Cyber Financial Fraud'),
                  subtitle: isTe ? 'ఆన్‌లైన్ బ్యాంకింగ్ మోసాలు & ఫిర్యాదులు' : (isHi ? 'वित्तीय साइबर धोखाधड़ी हेल्पलाइन' : 'National Cyber Crime Portal'),
                  color: const Color(0xFF8B5CF6),
                  icon: Icons.security_rounded,
                ),
                _helplineTile(
                  number: '1091',
                  title: tr('Women Helpline'),
                  subtitle: isTe ? 'మహిళా భద్రత & రక్షణ' : (isHi ? 'महिला सुरक्षा और सहायता' : 'Women Safety & Emergency Response'),
                  color: const Color(0xFFEC4899),
                  icon: Icons.female_rounded,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _helplineTile({
    required String number,
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: FilledButton.icon(
          onPressed: () => _makeCall(number),
          style: FilledButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.call_rounded, size: 15, color: Colors.white),
          label: Text(
            number,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 12.5,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTe = LocaleService.isTelugu;
    final isEmergencyTab = _tabController.index == 0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('Citizen Rights & Travel'),
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 18.5,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              isTe
                  ? 'అత్యవసర చట్టపరమైన రక్షణ & రైల్వే ప్రయాణ మార్గదర్శి'
                  : tr('Emergency legal protection & Indian Railway rules'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                color: isEmergencyTab ? const Color(0xFFDC2626) : const Color(0xFF0284C7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: _showHelplinesSheet,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.phone_in_talk_rounded, color: Colors.red, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '112 / 139',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: isEmergencyTab ? const Color(0xFFDC2626) : const Color(0xFF0284C7),
              indicatorWeight: 3,
              labelColor: isEmergencyTab ? const Color(0xFFDC2626) : const Color(0xFF0284C7),
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
              ),
              tabs: [
                Tab(
                  icon: const Icon(Icons.shield_rounded, size: 19),
                  text: tr('Emergency Rights'),
                ),
                Tab(
                  icon: const Icon(Icons.train_rounded, size: 19),
                  text: tr('Railway Rules'),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _KeepAlivePage(
            child: EmergencyGuideScreen(embedded: true),
          ),
          _KeepAlivePage(
            child: RailwayRulesScreen(embedded: true),
          ),
        ],
      ),
    );
  }
}

class _KeepAlivePage extends StatefulWidget {
  final Widget child;

  const _KeepAlivePage({required this.child});

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
