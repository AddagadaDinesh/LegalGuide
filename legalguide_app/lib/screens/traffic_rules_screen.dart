import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/traffic_data.dart';
import '../localization/app_strings.dart';
import '../services/locale_service.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';
import '../widgets/voice_search_modal.dart';
import '../widgets/watermark_background.dart';

class TrafficRulesScreen extends StatefulWidget {
  final int initialTabIndex;

  const TrafficRulesScreen({super.key, this.initialTabIndex = 0});

  @override
  State<TrafficRulesScreen> createState() => _TrafficRulesScreenState();
}

class _TrafficRulesScreenState extends State<TrafficRulesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
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

  Future<void> _openVoiceSearch() async {
    final spoken = await showVoiceSearchModal(
      context: context,
      hintText: tr('Search traffic fine, helmet, license, speed...'),
    );
    if (spoken != null && spoken.isNotEmpty) {
      _searchController.text = spoken;
    }
  }

  Future<void> _openUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTe = LocaleService.isTelugu;
    final isHi = LocaleService.isHindi;

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
              isTe ? 'ట్రాఫిక్ నిబంధనలు & జరిమానాలు' : (isHi ? 'ट्रैफिक नियम एवं चालान' : tr('Traffic Rules & Fines')),
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Motor Vehicles Amendment Act',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFFF59E0B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.accent,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(text: isTe ? 'జరిమానాలు' : tr('Fines & Offenses')),
            Tab(text: isTe ? 'డ్రైవర్ హక్కులు' : tr('Driver Rights')),
            Tab(text: isTe ? 'ఈ-చలానా చెకింగ్' : tr('E-Challan Guide')),
          ],
        ),
      ),
      body: WatermarkBackground(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildFinesTab(isTe),
            _buildRightsTab(isTe),
            _buildEChallanTab(isTe),
          ],
        ),
      ),
    );
  }

  // 1. Fines & Penalties Tab
  Widget _buildFinesTab(bool isTe) {
    final categories = ['All', 'High Severity', 'Safety', 'Documents', 'Signals'];

    final filteredFines = TrafficData.fines.where((f) {
      final matchesCategory = _selectedCategory == 'All' || f.category == _selectedCategory;
      if (!matchesCategory) return false;

      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery;
      return f.title.toLowerCase().contains(q) ||
          f.displayTitle.toLowerCase().contains(q) ||
          f.section.toLowerCase().contains(q) ||
          f.fineAmount.toLowerCase().contains(q) ||
          f.description.toLowerCase().contains(q) ||
          f.displayDescription.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        // Search & Voice Row
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          color: AppColors.surface,
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: isTe ? 'హెల్మెట్, లైసెన్స్, స్పీడ్, జరిమానా శోధించండి...' : tr('Search helmet, speed, drunk driving, license...'),
                      hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                      prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () => _searchController.clear(),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: _openVoiceSearch,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.mic_rounded, color: Color(0xFFF59E0B), size: 22),
                ),
              ),
            ],
          ),
        ),

        // Filter Chips
        Container(
          height: 46,
          padding: const EdgeInsets.symmetric(vertical: 6),
          color: AppColors.surface,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isSelected = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(
                    cat == 'All'
                        ? tr('All Fines')
                        : cat == 'High Severity'
                            ? (isTe ? 'భారీ జరిమానాలు' : 'High Severity')
                            : cat == 'Safety'
                                ? (isTe ? 'భద్రత' : 'Safety')
                                : cat == 'Documents'
                                    ? (isTe ? 'పత్రాలు' : 'Documents')
                                    : (isTe ? 'సిగ్నల్స్' : 'Signals'),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: const Color(0xFFF59E0B),
                  backgroundColor: AppColors.bg,
                  side: BorderSide(
                    color: isSelected ? const Color(0xFFF59E0B) : AppColors.border,
                  ),
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedCategory = cat);
                  },
                ),
              );
            },
          ),
        ),

        // List of Fines
        Expanded(
          child: filteredFines.isEmpty
              ? Center(
                  child: Text(
                    tr('No matching traffic fines found.'),
                    style: GoogleFonts.inter(color: AppColors.textSecondary),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredFines.length,
                  itemBuilder: (context, index) {
                    final item = filteredFines[index];
                    return _buildFineCard(item, isTe);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFineCard(TrafficFineItem item, bool isTe) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isSevere
              ? AppColors.danger.withValues(alpha: 0.35)
              : AppColors.border,
          width: item.isSevere ? 1.5 : 1,
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
            // Top Row: Section Badge & Severe Indicator & TTS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.section,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFD97706),
                    ),
                  ),
                ),
                Row(
                  children: [
                    ValueListenableBuilder<String?>(
                      valueListenable: TtsService.instance.currentlyPlayingId,
                      builder: (context, playingId, _) {
                        final isPlaying = playingId == 'traffic_${item.id}';
                        return IconButton(
                          icon: Icon(
                            isPlaying ? Icons.stop_circle_rounded : Icons.volume_up_rounded,
                            color: isPlaying ? Colors.red : const Color(0xFFF59E0B),
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          tooltip: tr(isPlaying ? 'Stop Reading' : 'Listen Aloud'),
                          onPressed: () {
                            final text = '${item.displayTitle}. ${item.section}. Penalty: ${item.fineAmount}. ${item.jailTerm != "None" ? "Jail: ${item.jailTerm}." : ""} ${item.displayDescription}.';
                            TtsService.instance.toggle(text: text, id: 'traffic_${item.id}');
                          },
                        );
                      },
                    ),
                    const SizedBox(width: 4),
                    if (item.isSevere)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isTe ? 'తీవ్రమైన నేరం' : 'HEAVY PENALTY',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.danger,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Title with Icon
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.icon, size: 22, color: item.isSevere ? AppColors.danger : const Color(0xFFF59E0B)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.displayTitle,
                    style: GoogleFonts.inter(
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

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

            // Penalty Summary Box
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
                          isTe ? 'జరిమానా' : tr('FINE AMOUNT'),
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            color: AppColors.danger,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.fineAmount,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (item.jailTerm != 'None') ...[
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
                            isTe ? 'జైలు శిక్ష' : tr('IMPRISONMENT'),
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              color: Colors.orange.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.jailTerm,
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 2. Driver Rights Tab
  Widget _buildRightsTab(bool isTe) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: TrafficData.driverRights.length,
      itemBuilder: (context, index) {
        final right = TrafficData.driverRights[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(right.icon, color: const Color(0xFF10B981), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isTe ? 'పౌర డ్రైవర్ హక్కు' : tr('CITIZEN DRIVER RIGHT'),
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF10B981),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            right.displayTitle,
                            style: GoogleFonts.inter(
                              fontSize: 15.5,
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
                        final isPlaying = playingId == 'driver_right_${right.id}';
                        return IconButton(
                          icon: Icon(
                            isPlaying ? Icons.stop_circle_rounded : Icons.volume_up_rounded,
                            color: isPlaying ? Colors.red : const Color(0xFF10B981),
                            size: 22,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          tooltip: tr(isPlaying ? 'Stop Reading' : 'Listen Aloud'),
                          onPressed: () {
                            final text = '${right.displayTitle}. ${right.displayDetail}. Legal basis: ${right.legalRef}.';
                            TtsService.instance.toggle(text: text, id: 'driver_right_${right.id}');
                          },
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  right.displayDetail,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.gavel_rounded, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          right.legalRef,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
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
      },
    );
  }

  // 3. E-Challan & Dispute Guide
  Widget _buildEChallanTab(bool isTe) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isTe ? 'అధికారిక ఈ-చలానా పోర్టల్' : tr('Official E-Challan Portal'),
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isTe ? 'మీ వాహన నంబర్ తో చలానాలను చెక్ చేసి ఆన్‌లైన్‌లో చెల్లించండి.' : tr('Check pending traffic challans & pay securely via Parivahan.'),
                        style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openUrl('https://echallan.parivahan.gov.in/'),
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: Text(
                    isTe ? 'పరివాహన్ ఈ-చలానా' : 'Parivahan Portal',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openUrl('https://vcourts.gov.in/'),
                  icon: const Icon(Icons.balance_rounded, size: 16),
                  label: Text(
                    isTe ? 'వర్చువల్ కోర్టు' : 'Virtual Courts',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Text(
            isTe ? 'తప్పుడు చలానా వస్తే ఏం చేయాలి?' : tr('How to Dispute a False / Wrong Challan?'),
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          _buildStepCard(
            stepNum: '1',
            title: isTe ? 'ఈ-చలానా ఫోటోను పరిశీలించండి' : tr('Inspect the Violation Photo Proof'),
            detail: isTe
                ? 'పరివాహన్ వెబ్‌సైట్‌లో లాగిన్ అయి సిగ్నల్ లేదా కెమెరా తీసిన ఫోటోను చూడండి. నంబర్ ప్లేట్ లేదా వాహనం మీది కాకపోతే వెంటనే స్క్రీన్‌షాట్ తీయండి.'
                : 'Log in to echallan.parivahan.gov.in and click "Detail" to examine the camera capture. Verify whether the license plate or vehicle actually matches yours.',
          ),
          _buildStepCard(
            stepNum: '2',
            title: isTe ? 'ఆన్‌లైన్ ఫిర్యాదును నమోదు చేయండి' : tr('File Online Grievance on Portal'),
            detail: isTe
                ? 'వెబ్‌సైట్‌లోని "Complaint / Grievance" ట్యాబ్‌పై క్లిక్ చేసి, తప్పుడు రీడింగ్ లేదా వేరే వాహనం అని పేర్కొంటూ ఫోటోలతో కంప్లైంట్ సబ్మిట్ చేయండి.'
                : 'Click the "Grievance" tab on the official portal. Upload proof (e.g. your vehicle photo showing differences or toll receipts proving your vehicle was elsewhere).',
          ),
          _buildStepCard(
            stepNum: '3',
            title: isTe ? 'వర్చువల్ కోర్టులో అప్పీల్ చేయండి' : tr('Contest via Virtual Court (vcourts.gov.in)'),
            detail: isTe
                ? 'చలానా వర్చువల్ కోర్టుకు వెళ్లినప్పుడు, "Contest Case" ఎంపికను ఎంచుకోవచ్చు. మేజిస్ట్రేట్ మీ అభ్యంతరాలను సమీక్షిస్తారు.'
                : 'If the challan is transferred to Virtual Court, you have the legal right to click "Contest Challan" instead of paying. A judicial magistrate will examine the case.',
          ),
          _buildStepCard(
            stepNum: '4',
            title: isTe ? 'లోక్ అదాలత్ (Lok Adalat) పరిష్కారం' : tr('Lok Adalat Discount / Settlement'),
            detail: isTe
                ? 'ఏటా జరిగే జాతీయ లోక్ అదాలత్‌లో ట్రాఫిక్ చలానాలపై భారీ రాయితీలు లేదా తప్పుడు చలానాలను పూర్తిగా రద్దు చేసుకునే అవకాశం ఉంటుంది.'
                : 'During quarterly National Lok Adalats, courts allow amicable settlement of pending traffic challans with substantial waivers or dismissal of contested fines.',
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard({required String stepNum, required String title, required String detail}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.15),
            child: Text(
              stepNum,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFD97706),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    height: 1.4,
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
