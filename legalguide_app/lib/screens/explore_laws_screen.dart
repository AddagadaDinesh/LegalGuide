import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/emergency_data.dart';
import '../data/railway_data.dart';
import '../localization/app_strings.dart';
import '../models/category.dart';
import '../models/legal_matter.dart';
import '../models/legal_section.dart';
import '../repositories/legal_data_repository.dart';
import '../services/bookmark_service.dart';
import '../services/locale_service.dart';
import '../services/search_history_service.dart';
import '../services/view_count_service.dart';
import '../theme/app_theme.dart';
import '../utils/section_lookup.dart';
import '../widgets/icon_badge.dart';
import '../widgets/legal_section_card.dart';
import '../widgets/section_heading.dart';
import '../widgets/voice_search_modal.dart';
import 'category_overview_screen.dart';
import 'citizen_rights_travel_screen.dart';
import 'documents_screen.dart';
import 'emergency_guide_screen.dart';
import 'legal_help_screen.dart';
import 'matter_detail_screen.dart';
import 'railway_rules_screen.dart';
import 'section_detail_screen.dart';
import 'traffic_rules_screen.dart';

class ExploreLawsScreen extends StatefulWidget {
  final int? lockedCategoryId;
  final String title;
  final bool showCategoryFilterBar;
  final bool showAppBar;
  final String? initialQuery;

  const ExploreLawsScreen({
    super.key,
    this.lockedCategoryId,
    this.title = 'Explore Laws',
    this.showCategoryFilterBar = true,
    this.showAppBar = false,
    this.initialQuery,
  });

  @override
  State<ExploreLawsScreen> createState() => _ExploreLawsScreenState();
}

class _ExploreLawsScreenState extends State<ExploreLawsScreen> {
  List<Category> _categories = [];
  List<LegalMatter> _matters = [];
  List<LegalSection> _sections = [];
  Set<int> _bookmarkedIds = {};
  Map<int, int> _viewCounts = {};
  SectionLookup? _lookup;
  bool _loading = true;

  int? _selectedCategoryId;
  late final TextEditingController _searchController;
  String _query = '';
  Timer? _searchRecordDebounce;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.lockedCategoryId;
    _query = widget.initialQuery ?? '';
    _searchController = TextEditingController(text: _query);
    _loadData();
  }

  Future<void> _loadData() async {
    final categories = await LegalDataRepository.loadCategories();
    final laws = await LegalDataRepository.loadLaws();
    final sections = await LegalDataRepository.loadSections();
    final matters = await LegalDataRepository.loadMatters();
    final bookmarks = await BookmarkService.getBookmarkedIds();
    final counts = await ViewCountService.getAllCounts();
    setState(() {
      _categories = categories;
      _sections = sections;
      _matters = matters;
      _bookmarkedIds = bookmarks;
      _viewCounts = counts;
      _lookup = SectionLookup(laws, categories);
      _loading = false;
    });
  }

  void _onQueryChanged(String value) {
    setState(() => _query = value.trim());
    _searchRecordDebounce?.cancel();
    _searchRecordDebounce = Timer(const Duration(milliseconds: 900), () {
      SearchHistoryService.recordQuery(value);
    });
  }

  Future<void> _openVoiceSearch() async {
    final spoken = await showVoiceSearchModal(
      context: context,
      hintText: tr('Say law name, section number, or topic...'),
    );
    if (spoken != null && spoken.isNotEmpty) {
      _searchController.text = spoken;
      _onQueryChanged(spoken);
    }
  }

  @override
  void dispose() {
    _searchRecordDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  List<Category> get _matchedCategories {
    if (_query.isEmpty) return [];
    final q = _query.toLowerCase();
    return _categories
        .where((c) => c.name.toLowerCase().contains(q) || c.displayName.toLowerCase().contains(q))
        .toList();
  }

  List<LegalMatter> get _matchedMatters {
    if (_query.isEmpty) return [];
    final q = _query.toLowerCase();
    return _matters
        .where((m) =>
            m.name.toLowerCase().contains(q) ||
            m.displayName.toLowerCase().contains(q) ||
            m.description.toLowerCase().contains(q) ||
            m.displayDescription.toLowerCase().contains(q))
        .toList();
  }

  List<Map<String, dynamic>> get _matchedFeatureGuides {
    if (_query.isEmpty || _selectedCategoryId != null) return [];
    final q = _query.toLowerCase();
    final guides = <Map<String, dynamic>>[];

    // Traffic Rules & Driver Rights
    if (q.contains('traffic') ||
        q.contains('challan') ||
        q.contains('helmet') ||
        q.contains('license') ||
        q.contains('licence') ||
        q.contains('seatbelt') ||
        q.contains('speed') ||
        q.contains('motor') ||
        q.contains('vehicle') ||
        q.contains('డ్రైవింగ్') ||
        q.contains('చలానా') ||
        q.contains('ట్రాఫిక్') ||
        q.contains('ट्रैफिक') ||
        q.contains('चालान')) {
      guides.add({
        'title': tr('Traffic Rules & Driver Rights'),
        'subtitle': tr('MV Act 2019 fines, e-challan disputes & citizen driver protections'),
        'icon': Icons.traffic_rounded,
        'color': const Color(0xFFD97706),
        'screen': const TrafficRulesScreen(),
      });
    }

    // Railway Rules Guide
    if (q.contains('railway') ||
        q.contains('train') ||
        q.contains('ticket') ||
        q.contains('chain') ||
        q.contains('రైల్వే') ||
        q.contains('రైలు') ||
        q.contains('रेलवे') ||
        q.contains('ट्रेन') ||
        q.contains('passenger')) {
      guides.add({
        'title': tr('Indian Railway Rules & Fines'),
        'subtitle': tr('Penalties, ticketless travel, chain pulling & passenger rights'),
        'icon': Icons.train_rounded,
        'color': const Color(0xFF0284C7),
        'screen': const CitizenRightsTravelScreen(initialTab: 1),
      });
    }

    // Emergency Rights Guide
    if (q.contains('emergency') ||
        q.contains('right') ||
        q.contains('police') ||
        q.contains('cyber') ||
        q.contains('women') ||
        q.contains('fraud') ||
        q.contains('stop') ||
        q.contains('అత్యవసర') ||
        q.contains('హక్కు') ||
        q.contains('పోలీస్') ||
        q.contains('आपातकालीन') ||
        q.contains('अधिकार') ||
        q.contains('पुलिस') ||
        q.contains('112') ||
        q.contains('1091') ||
        q.contains('1930')) {
      guides.add({
        'title': tr('Emergency Rights Guide'),
        'subtitle': tr('Police stops, traffic challans, cyber fraud & women safety rights'),
        'icon': Icons.shield_rounded,
        'color': const Color(0xFFDC2626),
        'screen': const CitizenRightsTravelScreen(initialTab: 0),
      });
    }

    // Legal Documents
    if (q.contains('document') ||
        q.contains('format') ||
        q.contains('affidavit') ||
        q.contains('పత్రాలు') ||
        q.contains('दस्तावेज़') ||
        q.contains('notice')) {
      guides.add({
        'title': tr('Legal Documents'),
        'subtitle': tr('Standard legal formats, notices, affidavits & petitions'),
        'icon': Icons.description_rounded,
        'color': const Color(0xFF14B8A6),
        'screen': const DocumentsScreen(),
      });
    }

    // Legal Help
    if (q.contains('help') ||
        q.contains('aid') ||
        q.contains('సహాయం') ||
        q.contains('मदद') ||
        q.contains('सहायता') ||
        q.contains('lawyer') ||
        q.contains('advocate')) {
      guides.add({
        'title': tr('Need Legal Help'),
        'subtitle': tr('Free legal aid, emergency helplines & court assistance'),
        'icon': Icons.support_agent_rounded,
        'color': const Color(0xFFF43F5E),
        'screen': const LegalHelpScreen(),
      });
    }

    return guides;
  }

  List<EmergencyScenario> get _matchedEmergencyScenarios {
    if (_query.isEmpty || _selectedCategoryId != null) return [];
    final q = _query.toLowerCase();
    final isGeneral = q.contains('emergency') ||
        q.contains('right') ||
        q.contains('అత్యవసర') ||
        q.contains('హక్కులు') ||
        q.contains('आपातकालीन') ||
        q.contains('अधिकार');

    return emergencyScenarios.where((scenario) {
      if (isGeneral) return true;
      if (scenario.title.toLowerCase().contains(q) ||
          scenario.titleTe.toLowerCase().contains(q) ||
          scenario.subtitle.toLowerCase().contains(q) ||
          scenario.subtitleTe.toLowerCase().contains(q) ||
          scenario.emergencyNumber.contains(q) ||
          (scenario.directSearchQuery?.toLowerCase().contains(q) ?? false)) {
        return true;
      }
      for (final step in scenario.steps) {
        if (step.title.toLowerCase().contains(q) ||
            step.titleTe.toLowerCase().contains(q) ||
            step.description.toLowerCase().contains(q) ||
            step.descriptionTe.toLowerCase().contains(q) ||
            step.legalGround.toLowerCase().contains(q)) {
          return true;
        }
      }
      for (final k in [
        ...scenario.doKeywords,
        ...scenario.dontKeywords,
        ...scenario.doKeywordsTe,
        ...scenario.dontKeywordsTe,
      ]) {
        if (k.toLowerCase().contains(q)) return true;
      }
      return false;
    }).toList();
  }

  List<RailwayFineItem> get _matchedRailwayFines {
    if (_query.isEmpty || _selectedCategoryId != null) return [];
    final q = _query.toLowerCase();
    final isGeneral = q.contains('railway') ||
        q.contains('train') ||
        q.contains('రైల్వే') ||
        q.contains('రైలు') ||
        q.contains('रेलवे') ||
        q.contains('ट्रेन') ||
        q == 'fine' ||
        q == 'fines' ||
        q == 'జరిమానా' ||
        q == 'जुर्माना' ||
        q == 'ticket' ||
        q == 'టికెట్' ||
        q == 'टिकट' ||
        q.contains('passenger');

    return RailwayData.fines.where((fine) {
      if (isGeneral) return true;
      return fine.title.toLowerCase().contains(q) ||
          fine.titleTe.toLowerCase().contains(q) ||
          fine.section.toLowerCase().contains(q) ||
          fine.description.toLowerCase().contains(q) ||
          fine.descriptionTe.toLowerCase().contains(q) ||
          fine.fineAmount.toLowerCase().contains(q);
    }).toList();
  }

  bool _matchesMultilingualKeywords(LegalSection section, String q) {
    final title = section.title.toLowerCase();
    final keywords = section.keywords.toLowerCase();

    // Theft / Robbery
    if (q.contains('theft') ||
        q.contains('chori') ||
        q.contains('chor') ||
        q.contains('dongathanam') ||
        q.contains('donga') ||
        q.contains('thiruttu') ||
        q.contains('kallathana') ||
        q.contains('దొంగ') ||
        q.contains('చోరీ') ||
        q.contains('చోరి') ||
        q.contains('चोरी') ||
        q.contains('திருட்டு')) {
      if (title.contains('theft') || keywords.contains('theft')) return true;
    }

    // Cheating / Fraud
    if (q.contains('cheat') ||
        q.contains('fraud') ||
        q.contains('scam') ||
        q.contains('dhokh') ||
        q.contains('dhoka') ||
        q.contains('mosam') ||
        q.contains('yematram') ||
        q.contains('మోసం') ||
        q.contains('ధోఖా') ||
        q.contains('धोखा') ||
        q == '420') {
      if (title.contains('cheat') || keywords.contains('cheating') || section.sectionNumber.contains('318') || section.sectionNumber.contains('420')) return true;
    }

    // Murder / Killing
    if (q.contains('murder') ||
        q.contains('kill') ||
        q.contains('hatya') ||
        q.contains('hathya') ||
        q.contains('kolai') ||
        q.contains('హత్య') ||
        q.contains('చంప') ||
        q.contains('हत्या') ||
        q == '302') {
      if (title.contains('murder') || keywords.contains('murder') || section.sectionNumber.contains('103') || section.sectionNumber.contains('302')) return true;
    }

    // Arrest / Detention / Police
    if (q.contains('arrest') ||
        q.contains('detention') ||
        q.contains('jail') ||
        q.contains('police') ||
        q.contains('lockup') ||
        q.contains('ఖైదు') ||
        q.contains('అరెస్ట్') ||
        q.contains('పోలీస్') ||
        q.contains('गिरफ़्तारी') ||
        q.contains('हिरासत') ||
        q.contains('जेल') ||
        q.contains('पुलिस')) {
      if (title.contains('arrest') || keywords.contains('arrest') || section.sectionNumber.contains('35')) return true;
    }

    // Bail
    if (q.contains('bail') ||
        q.contains('zamanat') ||
        q.contains('bellu') ||
        q.contains('బెయిల్') ||
        q.contains('జామీను') ||
        q.contains('जमानत')) {
      if (title.contains('bail') || keywords.contains('bail')) return true;
    }

    // FIR / Complaint
    if (q.contains('fir') ||
        q.contains('complaint') ||
        q.contains('police report') ||
        q.contains('ఫిర్యాదు') ||
        q.contains('ఎఫ్‌ఐఆర్') ||
        q.contains('शिकायत') ||
        q.contains('एफआईआर')) {
      if (title.contains('fir') || title.contains('information to police') || keywords.contains('fir') || section.sectionNumber.contains('173')) return true;
    }

    // Dowry / Women protection
    if (q.contains('dowry') ||
        q.contains('domestic') ||
        q.contains('women') ||
        q.contains('stree') ||
        q.contains('mahila') ||
        q.contains('వరకట్నం') ||
        q.contains('మహిళ') ||
        q.contains('दहेज') ||
        q.contains('महिला')) {
      if (title.contains('dowry') || title.contains('cruelty') || title.contains('woman') || keywords.contains('dowry')) return true;
    }

    // Accident / Driving
    if (q.contains('accident') ||
        q.contains('rash') ||
        q.contains('driving') ||
        q.contains('traffic') ||
        q.contains('challan') ||
        q.contains('ప్రమాదం') ||
        q.contains('యాక్సిడెంట్') ||
        q.contains('दुर्घटना')) {
      if (title.contains('rash') || title.contains('accident') || keywords.contains('driving') || section.sectionNumber.contains('106')) return true;
    }

    return false;
  }

  List<LegalSection> get _filtered {
    final lookup = _lookup;
    if (lookup == null) return [];
    return _sections.where((section) {
      if (_selectedCategoryId != null) {
        final category = lookup.categoryFor(section);
        if (category?.id != _selectedCategoryId) return false;
      }
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return section.sectionNumber.toLowerCase().contains(q) ||
          section.title.toLowerCase().contains(q) ||
          section.titleTe.toLowerCase().contains(q) ||
          section.displayTitle.toLowerCase().contains(q) ||
          section.simpleExplanation.toLowerCase().contains(q) ||
          section.simpleExplanationTe.toLowerCase().contains(q) ||
          section.displaySimpleExplanation.toLowerCase().contains(q) ||
          section.displayPurpose.toLowerCase().contains(q) ||
          section.displayPunishment.toLowerCase().contains(q) ||
          section.legalText.toLowerCase().contains(q) ||
          section.relevantDocuments.toLowerCase().contains(q) ||
          section.keywords.toLowerCase().contains(q) ||
          _matchesMultilingualKeywords(section, q);
    }).toList();
  }

  Future<void> _toggleBookmark(int sectionId) async {
    await BookmarkService.toggle(sectionId);
    final bookmarks = await BookmarkService.getBookmarkedIds();
    setState(() => _bookmarkedIds = bookmarks);
  }

  void _openSection(LegalSection section) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SectionDetailScreen(section: section)),
    );
    final counts = await ViewCountService.getAllCounts();
    final bookmarks = await BookmarkService.getBookmarkedIds();
    if (mounted) {
      setState(() {
        _viewCounts = counts;
        _bookmarkedIds = bookmarks;
      });
    }
  }

  Widget _buildContent() {
    final lookup = _lookup;
    if (_loading || lookup == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

    final filtered = _filtered;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!widget.showAppBar)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Text(
                      tr(widget.title),
                      style: GoogleFonts.outfit(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                TextField(
                  controller: _searchController,
                  style: GoogleFonts.inter(color: AppColors.textPrimary),
                  onChanged: _onQueryChanged,
                  decoration: InputDecoration(
                    hintText: tr('Search laws, section numbers, topics...'),
                    hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.accent),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_query.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 20, color: AppColors.textMuted),
                            onPressed: () {
                              _searchController.clear();
                              _onQueryChanged('');
                            },
                          ),
                        IconButton(
                          icon: const Icon(Icons.mic_rounded, color: AppColors.accent, size: 22),
                          tooltip: tr('Speak to search'),
                          onPressed: _openVoiceSearch,
                        ),
                        const SizedBox(width: 4),
                      ],
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
                    ),
                  ),
                ),
                if (widget.showCategoryFilterBar) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        ChoiceChip(
                          label: Text(tr('All')),
                          selected: _selectedCategoryId == null,
                          onSelected: (_) => setState(() => _selectedCategoryId = null),
                          selectedColor: AppColors.accent,
                          backgroundColor: AppColors.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            side: const BorderSide(color: AppColors.border),
                          ),
                          labelStyle: GoogleFonts.inter(
                            color: _selectedCategoryId == null ? Colors.white : AppColors.textPrimary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        for (final category in _categories) ...[
                          ChoiceChip(
                            label: Text(category.displayName),
                            selected: _selectedCategoryId == category.id,
                            onSelected: (_) => setState(() => _selectedCategoryId = category.id),
                            selectedColor: categoryStyleFor(category.name).color,
                            backgroundColor: AppColors.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                              side: const BorderSide(color: AppColors.border),
                            ),
                            labelStyle: GoogleFonts.inter(
                              color: _selectedCategoryId == category.id ? Colors.white : AppColors.textPrimary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_query.isNotEmpty &&
            (_matchedFeatureGuides.isNotEmpty ||
                _matchedEmergencyScenarios.isNotEmpty ||
                _matchedRailwayFines.isNotEmpty ||
                _matchedCategories.isNotEmpty ||
                _matchedMatters.isNotEmpty))
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_matchedFeatureGuides.isNotEmpty) ...[
                    SectionHeading(
                      title: '${tr("Special Guides & Acts")} (${_matchedFeatureGuides.length})',
                      icon: Icons.auto_awesome_rounded,
                    ),
                    const SizedBox(height: 8),
                    for (final guide in _matchedFeatureGuides)
                      _buildResultTile(
                        icon: guide['icon'] as IconData,
                        color: guide['color'] as Color,
                        title: guide['title'] as String,
                        subtitle: guide['subtitle'] as String,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => guide['screen'] as Widget),
                        ),
                      ),
                    const SizedBox(height: 14),
                  ],
                  if (_matchedEmergencyScenarios.isNotEmpty) ...[
                    SectionHeading(
                      title: '${tr("Emergency Protections")} (${_matchedEmergencyScenarios.length})',
                      icon: Icons.shield_rounded,
                    ),
                    const SizedBox(height: 8),
                    for (final scenario in _matchedEmergencyScenarios)
                      _buildEmergencyScenarioCard(scenario),
                    const SizedBox(height: 14),
                  ],
                  if (_matchedRailwayFines.isNotEmpty) ...[
                    SectionHeading(
                      title: '${tr("Railway Fines & Offences")} (${_matchedRailwayFines.length})',
                      icon: Icons.train_rounded,
                    ),
                    const SizedBox(height: 8),
                    for (final fine in _matchedRailwayFines)
                      _buildRailwayFineCard(fine),
                    const SizedBox(height: 14),
                  ],
                  if (_matchedCategories.isNotEmpty) ...[
                    SectionHeading(title: '${tr("Categories")} (${_matchedCategories.length})'),
                    const SizedBox(height: 8),
                    for (final category in _matchedCategories)
                      _buildResultTile(
                        icon: categoryStyleFor(category.name).icon,
                        color: categoryStyleFor(category.name).color,
                        title: category.displayName,
                        subtitle: category.displayDescription,
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (context) => CategoryOverviewScreen(category: category))),
                      ),
                    const SizedBox(height: 14),
                  ],
                  if (_matchedMatters.isNotEmpty) ...[
                    SectionHeading(title: '${tr("Topics")} (${_matchedMatters.length})'),
                    const SizedBox(height: 8),
                    for (final matter in _matchedMatters)
                      _buildResultTile(
                        icon: matter.isAvailable ? Icons.topic_rounded : Icons.hourglass_empty_rounded,
                        color: matter.isAvailable ? AppColors.accent : AppColors.textMuted,
                        title: matter.displayName,
                        subtitle: matter.displayDescription.isNotEmpty
                            ? matter.displayDescription
                            : (matter.isAvailable
                                ? tr('View related legal sections')
                                : tr('Content coming soon — not yet verified')),
                        onTap: () {
                          if (!matter.isAvailable) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('"${matter.displayName}" ${tr("content is coming soon — not yet verified.")}')),
                            );
                            return;
                          }
                          Navigator.push(context,
                              MaterialPageRoute(builder: (context) => MatterDetailScreen(matter: matter)));
                        },
                      ),
                    const SizedBox(height: 14),
                  ],
                ],
              ),
            ),
          ),
        if (filtered.isNotEmpty ||
            (_matchedFeatureGuides.isEmpty &&
                _matchedEmergencyScenarios.isEmpty &&
                _matchedRailwayFines.isEmpty &&
                _matchedCategories.isEmpty &&
                _matchedMatters.isEmpty)) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: SectionHeading(
                title: _query.isEmpty
                    ? '${tr("Available Provisions")} (${filtered.length})'
                    : '${tr("Sections")} (${filtered.length})',
                icon: Icons.menu_book_rounded,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
        ],
        if (filtered.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: _matchedFeatureGuides.isEmpty &&
                      _matchedEmergencyScenarios.isEmpty &&
                      _matchedRailwayFines.isEmpty &&
                      _matchedCategories.isEmpty &&
                      _matchedMatters.isEmpty
                  ? Center(
                      child: Column(
                        children: [
                          const Icon(Icons.search_off_rounded, size: 44, color: AppColors.textMuted),
                          const SizedBox(height: 10),
                          Text(
                            tr('No matching legal sections or guides found.'),
                            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13.5),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final section = filtered[index];
                  return LegalSectionCard(
                    section: section,
                    lawShortName: lookup.lawShortNameFor(section),
                    breadcrumb: lookup.breadcrumbFor(section),
                    isBookmarked: _bookmarkedIds.contains(section.id),
                    isFrequentlyViewed:
                        (_viewCounts[section.id] ?? 0) >= ViewCountService.frequentThreshold,
                    accentColor: categoryStyleFor(lookup.categoryNameFor(section)).color,
                    onBookmarkToggle: () => _toggleBookmark(section.id),
                    onTap: () => _openSection(section),
                  );
                },
                childCount: filtered.length,
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }

  Widget _buildResultTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          leading: IconBadge(icon: icon, color: color, size: 40, iconSize: 20),
          title: Text(title, style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
          subtitle: Text(subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _buildEmergencyScenarioCard(EmergencyScenario scenario) {
    final isTe = LocaleService.isTelugu;
    final isHi = LocaleService.isHindi;
    final title = isTe && scenario.titleTe.isNotEmpty
        ? scenario.titleTe
        : (isHi ? tr(scenario.title) : scenario.title);
    final subtitle = isTe && scenario.subtitleTe.isNotEmpty
        ? scenario.subtitleTe
        : (isHi ? tr(scenario.subtitle) : scenario.subtitle);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scenario.themeColor.withValues(alpha: 0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EmergencyGuideScreen()),
            );
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: scenario.themeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(scenario.icon, color: scenario.themeColor, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            scenario.emergencyNumberLabel,
                            style: GoogleFonts.inter(
                              color: scenario.themeColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRailwayFineCard(RailwayFineItem fine) {
    final isTe = LocaleService.isTelugu;
    final isHi = LocaleService.isHindi;
    final title = isTe && fine.titleTe.isNotEmpty
        ? fine.titleTe
        : (isHi ? tr(fine.title) : fine.title);
    final description = isTe && fine.descriptionTe.isNotEmpty
        ? fine.descriptionTe
        : (isHi ? tr(fine.description) : fine.description);

    final bailableLabel = fine.isBailable
        ? (isTe ? 'బెయిలబుల్' : (isHi ? 'जमानती' : 'Bailable'))
        : (isTe ? 'నాన్-బెయిలబుల్' : (isHi ? 'गैर-जमानती' : 'Non-Bailable'));

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RailwayRulesScreen()),
            );
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        fine.section,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF0284C7),
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (fine.isBailable ? Colors.green : Colors.red).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        bailableLabel,
                        style: GoogleFonts.inter(
                          color: fine.isBailable ? Colors.green : Colors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.monetization_on_outlined, size: 14, color: AppColors.warning),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        fine.fineAmount,
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      isTe ? 'రైల్వే నిబంధనలలో చూడండి →' : (isHi ? 'नियम देखें →' : 'View in Rules →'),
                      style: GoogleFonts.inter(
                        color: const Color(0xFF0284C7),
                        fontWeight: FontWeight.w600,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showAppBar) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          title: Text(
            tr(widget.title),
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
        ),
        body: SafeArea(child: _buildContent()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(child: _buildContent()),
    );
  }
}
