import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/railway_data.dart';
import '../localization/app_strings.dart';
import '../services/analytics_service.dart';
import '../services/locale_service.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';
import '../widgets/voice_search_modal.dart';
import '../widgets/watermark_background.dart';

class RailwayRulesScreen extends StatefulWidget {
  final bool embedded;

  const RailwayRulesScreen({super.key, this.embedded = false});

  @override
  State<RailwayRulesScreen> createState() => _RailwayRulesScreenState();
}

class _RailwayRulesScreenState extends State<RailwayRulesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    AnalyticsService.trackFeature('railway_rules');
    AnalyticsService.trackFeature('legal_awareness');
    _tabController = TabController(length: 4, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    TtsService.instance.stop();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _makeCall(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openVoiceSearch() async {
    final spoken = await showVoiceSearchModal(
      context: context,
      hintText: tr('Search fines, rules, chain, ticket...'),
    );
    if (spoken != null && spoken.isNotEmpty) {
      _searchController.text = spoken;
    }
  }

  Widget _buildSearchAndTabBar(bool isTe) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search Input
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: tr('Search fines, chain, ticket, rules...'),
                hintStyle: GoogleFonts.inter(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textMuted,
                  size: 20,
                ),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchQuery.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () => _searchController.clear(),
                      ),
                    IconButton(
                      icon: const Icon(Icons.mic_rounded, size: 20, color: Color(0xFF0284C7)),
                      tooltip: tr('Speak to search'),
                      onPressed: _openVoiceSearch,
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
        // TabBar
        TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: const Color(0xFF0284C7), // Railway Blue
          indicatorWeight: 3,
          labelColor: const Color(0xFF0284C7),
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          tabs: [
            Tab(
              icon: const Icon(Icons.money_off_csred_rounded, size: 18),
              text: tr('Fines & Penalties'),
            ),
            Tab(
              icon: const Icon(Icons.fact_check_rounded, size: 18),
              text: tr("Do's & Don'ts"),
            ),
            Tab(
              icon: const Icon(Icons.gavel_rounded, size: 18),
              text: tr('Bare Act Sections'),
            ),
            Tab(
              icon: const Icon(Icons.phone_in_talk_rounded, size: 18),
              text: tr('Helplines & Rights'),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LocaleService.language,
      builder: (context, currentLanguage, _) {
        final isTe = LocaleService.isTelugu;
        final searchAndTabBar = _buildSearchAndTabBar(isTe);
        final tabBarView = WatermarkBackground(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildFinesTab(isTe),
              _buildRulesTab(isTe),
              _buildSectionsTab(isTe),
              _buildHelplinesTab(isTe),
            ],
          ),
        );

        if (widget.embedded) {
          return Scaffold(
            backgroundColor: AppColors.bg,
            body: Column(
              children: [
                Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.only(top: 6),
                  child: searchAndTabBar,
                ),
                Expanded(child: tabBarView),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            title: Text(
              tr('Railway Rules & Fines'),
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                fontSize: 20,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(104),
              child: searchAndTabBar,
            ),
          ),
          body: tabBarView,
        );
      },
    );
  }

  // 1. Fines & Penalties Tab
  Widget _buildFinesTab(bool isTe) {
    final filteredFines = RailwayData.fines.where((f) {
      if (_searchQuery.isEmpty) return true;
      return f.title.toLowerCase().contains(_searchQuery) ||
          f.section.toLowerCase().contains(_searchQuery) ||
          f.fineAmount.toLowerCase().contains(_searchQuery) ||
          f.description.toLowerCase().contains(_searchQuery) ||
          f.titleTe.toLowerCase().contains(_searchQuery);
    }).toList();

    if (filteredFines.isEmpty) {
      return Center(
        child: Text(
          isTe ? 'ఫలితాలు కనుగొనబడలేదు' : tr('No matching penalties found'),
          style: GoogleFonts.inter(color: AppColors.textMuted),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredFines.length,
      itemBuilder: (context, index) {
        final item = filteredFines[index];
        final isSevere = item.severity == 'High';

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSevere
                  ? AppColors.danger.withValues(alpha: 0.3)
                  : AppColors.border,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Section badge & Bailability
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.section,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0284C7),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        ValueListenableBuilder<String?>(
                          valueListenable: TtsService.instance.currentlyPlayingId,
                          builder: (context, playingId, _) {
                            final isPlaying = playingId == 'railway_${item.section}';
                            return IconButton(
                              icon: Icon(
                                isPlaying ? Icons.stop_circle_rounded : Icons.volume_up_rounded,
                                color: isPlaying ? Colors.red : const Color(0xFF0284C7),
                                size: 20,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              tooltip: tr(isPlaying ? 'Stop Reading' : 'Listen Aloud'),
                              onPressed: () {
                                final text = '${item.displayTitle}. Section ${item.section}. ${item.displayDescription}. Fine: ${item.fineAmount}. Jail: ${item.jailTerm}.';
                                TtsService.instance.toggle(text: text, id: 'railway_${item.section}');
                              },
                            );
                          },
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: item.isBailable
                                ? AppColors.success.withValues(alpha: 0.12)
                                : AppColors.danger.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.isBailable ? tr('Bailable') : tr('Non-Bailable'),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: item.isBailable
                                  ? AppColors.success
                                  : AppColors.danger,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Offense Title
                Text(
                  item.displayTitle,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                // Description
                Text(
                  item.displayDescription,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 12),
                // Penalty Box
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr('FINE AMOUNT'),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.danger,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item.fineAmount,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr('IMPRISONMENT'),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.orange.shade800,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item.jailTerm,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
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
          ),
        );
      },
    );
  }

  // 2. Do's & Don'ts Tab
  Widget _buildRulesTab(bool isTe) {
    final filteredRules = RailwayData.rules.where((r) {
      if (_searchQuery.isEmpty) return true;
      return r.title.toLowerCase().contains(_searchQuery) ||
          r.detail.toLowerCase().contains(_searchQuery) ||
          r.titleTe.toLowerCase().contains(_searchQuery) ||
          r.legalRef.toLowerCase().contains(_searchQuery);
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredRules.length,
      itemBuilder: (context, index) {
        final rule = filteredRules[index];
        final isAllowed = rule.isAllowed;

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isAllowed
                  ? AppColors.success.withValues(alpha: 0.3)
                  : AppColors.danger.withValues(alpha: 0.3),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isAllowed
                            ? AppColors.success.withValues(alpha: 0.15)
                            : AppColors.danger.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isAllowed
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        size: 20,
                        color: isAllowed ? AppColors.success : AppColors.danger,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAllowed
                                ? tr('ALLOWED / RULE')
                                : tr('STRICTLY PROHIBITED'),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isAllowed
                                  ? AppColors.success
                                  : AppColors.danger,
                            ),
                          ),
                          Text(
                            rule.displayTitle,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ValueListenableBuilder<String?>(
                      valueListenable: TtsService.instance.currentlyPlayingId,
                      builder: (context, playingId, _) {
                        final isPlaying = playingId == 'railway_right_${rule.title}';
                        return IconButton(
                          icon: Icon(
                            isPlaying ? Icons.stop_circle_rounded : Icons.volume_up_rounded,
                            color: isPlaying ? Colors.red : const Color(0xFF0284C7),
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          tooltip: tr(isPlaying ? 'Stop Reading' : 'Listen Aloud'),
                          onPressed: () {
                            final text = '${rule.displayTitle}. ${rule.displayDetail}. Reference: ${rule.legalRef}.';
                            TtsService.instance.toggle(text: text, id: 'railway_right_${rule.title}');
                          },
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  rule.displayDetail,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${tr("Reference")}: ${rule.legalRef}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 3. Bare Act Sections Tab
  Widget _buildSectionsTab(bool isTe) {
    final filteredSections = RailwayData.sections.where((s) {
      if (_searchQuery.isEmpty) return true;
      return s.sectionNumber.toLowerCase().contains(_searchQuery) ||
          s.title.toLowerCase().contains(_searchQuery) ||
          s.simpleExplanation.toLowerCase().contains(_searchQuery);
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredSections.length,
      itemBuilder: (context, index) {
        final sec = filteredSections[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            shape: const Border(),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.gavel_rounded,
                color: Color(0xFF0284C7),
                size: 22,
              ),
            ),
            title: Text(
              sec.sectionNumber,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: const Color(0xFF0284C7),
              ),
            ),
            subtitle: Text(
              tr(sec.title),
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            childrenPadding: const EdgeInsets.all(16),
            children: [
              // Simple Explanation
              _sectionBlock(
                title: tr('Simple Explanation'),
                content: tr(sec.simpleExplanation),
                color: Colors.blue.shade700,
              ),
              const SizedBox(height: 12),
              // Punishment
              _sectionBlock(
                title: tr('Punishment & Penalties'),
                content: tr(sec.punishment),
                color: AppColors.danger,
              ),
              const SizedBox(height: 12),
              // Practical Example
              _sectionBlock(
                title: tr('Practical Scenario'),
                content: tr(sec.practicalExample),
                color: AppColors.success,
              ),
              const SizedBox(height: 12),
              // Legal Text
              _sectionBlock(
                title: tr('Official Statutory Legal Text'),
                content: sec.legalText,
                color: AppColors.textMuted,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionBlock({
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // 4. Helplines & Passenger Rights Tab
  Widget _buildHelplinesTab(bool isTe) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Hero 139 Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0369A1), Color(0xFF0284C7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tr('ALL-IN-ONE HELPLINE'),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Icon(Icons.support_agent_rounded, color: Colors.white, size: 28),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'RailMadad: Dial 139',
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                tr('24x7 integrated railway helpline for security, medical emergencies, catering, cleanliness, and passenger grievances.'),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.9),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: () => _makeCall('139'),
                icon: const Icon(Icons.phone_rounded, color: Color(0xFF0369A1)),
                label: Text(
                  tr('Call 139 Now'),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0369A1),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Direct Contact Tiles
        Text(
          tr('Emergency Contacts'),
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        _helplineTile(
          title: 'Railway Protection Force (RPF) Security',
          number: '182',
          desc: 'Immediate armed security response for theft, harassment, or crime.',
          icon: Icons.shield_rounded,
          color: AppColors.danger,
        ),
        _helplineTile(
          title: 'Women Passenger Safety Helpline',
          number: '182',
          desc: 'Special RPF Meri Saheli female escort teams in trains.',
          icon: Icons.female_rounded,
          color: const Color(0xFFEC4899),
        ),
        _helplineTile(
          title: 'National Emergency Support (Police / Ambulance)',
          number: '112',
          desc: 'Unified national emergency helpline available nationwide.',
          icon: Icons.local_hospital_rounded,
          color: AppColors.success,
        ),
        const SizedBox(height: 20),
        // Key Rights
        Text(
          tr('Key Passenger Rights'),
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        _rightItem(
          'TTE Ticket Verification Hours',
          'TTEs cannot disturb sleeping passengers for tickets between 10:00 PM and 6:00 AM, except for passengers who boarded at stations after 10:00 PM.',
        ),
        _rightItem(
          'Emergency Medical Aid on Trains',
          'Every train superintendent/guard carries a first-aid box. For severe illness, TTE must inform the upcoming station master to arrange an on-platform doctor.',
        ),
        _rightItem(
          'Refund on Train Delays (> 3 Hours)',
          'If a train is delayed by more than 3 hours, passengers have the right to cancel their ticket and receive a full refund without cancellation deduction (TDR).',
        ),
      ],
    );
  }

  Widget _helplineTile({
    required String title,
    required String number,
    required String desc,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          tr(title),
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              tr(desc),
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              '${tr("Dial")} $number',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.call_rounded, color: color),
          onPressed: () => _makeCall(number),
        ),
      ),
    );
  }

  Widget _rightItem(String title, String detail) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_rounded, size: 16, color: Color(0xFF0284C7)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tr(title),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            tr(detail),
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
