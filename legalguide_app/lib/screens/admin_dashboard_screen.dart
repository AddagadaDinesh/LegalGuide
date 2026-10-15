import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../localization/app_strings.dart';
import '../models/law.dart';
import '../repositories/legal_data_repository.dart';
import '../services/admin_analytics_service.dart';
import '../services/auth_service.dart';
import 'admin_act_detail_screen.dart';
import 'login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  String? _userErrorMessage;
  String? _noticeMessage;
  bool _isForbidden = false;

  AdminAnalyticsData? _analytics;
  AdminUsersResult? _usersResult;
  List<AdminUserData>? _users;
  Map<String, dynamic>? _adminStatus;

  String _userSearchQuery = '';
  String _selectedRoleFilter = 'ALL'; // 'ALL', 'USER', 'ADMIN', 'ACTIVE'
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _deletingUserIds = <String>{};

  List<Law>? _acts;
  String _actSearchQuery = '';
  String _selectedActStatusFilter = 'ALL';
  String _selectedActDomainFilter = 'ALL';
  final TextEditingController _actSearchController = TextEditingController();

  List<AdminPendingUpdateRecord>? _pendingUpdates;
  AdminPendingUpdatesResult? _pendingUpdatesResult;
  String? _pendingUpdatesError;
  final Map<int, TextEditingController> _updateNotesControllers = {};
  final Set<int> _processingUpdateIds = {};

  Future<void> _confirmAndDeleteUser(AdminUserData u) async {
    final currentAdmin = AuthService.currentUsername.value ?? 'Admin';
    if (u.username.trim().toLowerCase() == currentAdmin.trim().toLowerCase()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('You cannot delete your own admin account.')),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_deletingUserIds.contains(u.id)) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF334155)),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                tr('Delete User'),
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('Are you sure you want to delete this user? This action cannot be undone.'),
              style: GoogleFonts.inter(
                color: const Color(0xFFCBD5E1),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_outline_rounded, color: Color(0xFF94A3B8), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${u.username} (${u.email.isNotEmpty ? u.email : tr("Not provided")})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text(
              tr('Cancel'),
              style: GoogleFonts.inter(
                color: const Color(0xFF94A3B8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: Text(
              tr('Delete'),
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) return;

    setState(() {
      _deletingUserIds.add(u.id);
    });

    try {
      final result = await AdminAnalyticsService.deleteUser(u.id, username: u.username);
      if (!mounted) return;

      if (result.success) {
        // Immediate UI removal and local count decrease
        setState(() {
          _users?.removeWhere((item) => item.id == u.id);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? tr('User deleted successfully.')),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Requirement 14: Refresh/re-fetch users and counts from backend so displayed data always matches database
        await _loadData(showRefreshing: true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? tr('Failed to delete user.')),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _deletingUserIds.remove(u.id);
        });
      }
    }
  }


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _actSearchController.dispose();
    for (final c in _updateNotesControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData({bool showRefreshing = false}) async {
    if (showRefreshing) {
      setState(() => _isRefreshing = true);
    } else {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _userErrorMessage = null;
        _noticeMessage = null;
        _isForbidden = false;
      });
    }

    final results = await Future.wait([
      AdminAnalyticsService.fetchAnalytics(),
      AdminAnalyticsService.fetchUsers(),
      AdminAnalyticsService.fetchAdminStatus(),
      AdminAnalyticsService.fetchAdminActs(),
      AdminAnalyticsService.fetchPendingUpdates(),
    ]);

    if (!mounted) return;

    final analyticsResult = results[0] as AdminAnalyticsResult;
    final usersResult = results[1] as AdminUsersResult;
    final statusResult = results[2] as Map<String, dynamic>?;
    final actsResult = results[3] as List<Law>;
    final updatesResult = results[4] as AdminPendingUpdatesResult;

    setState(() {
      _isLoading = false;
      _isRefreshing = false;
      _acts = actsResult;
      _pendingUpdatesResult = updatesResult;
      _pendingUpdates = updatesResult.updates;
      _pendingUpdatesError = updatesResult.success ? null : updatesResult.error;

      for (final u in updatesResult.updates) {
        if (!_updateNotesControllers.containsKey(u.id)) {
          _updateNotesControllers[u.id] = TextEditingController(text: u.adminNotes ?? '');
        }
      }

      // Analytics
      if (analyticsResult.success && analyticsResult.data != null) {
        _analytics = analyticsResult.data;
        _noticeMessage = analyticsResult.isFallback ? analyticsResult.error : null;
        _errorMessage = null;
        _isForbidden = false;
      } else {
        _errorMessage = analyticsResult.error ?? tr('Failed to load analytics.');
        _isForbidden = analyticsResult.isForbidden;
      }

      // User Directory
      _usersResult = usersResult;
      if (usersResult.success) {
        _users = usersResult.users;
        _userErrorMessage = null;
      } else {
        _users = usersResult.users;
        _userErrorMessage = usersResult.error ?? tr('Failed to load user directory.');
      }

      // Admin Status
      _adminStatus = statusResult;
    });
  }


  @override
  Widget build(BuildContext context) {
    final currentAdmin = AuthService.currentUsername.value ?? 'Admin';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark slate theme
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  tr('Admin Dashboard'),
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF6366F1), width: 1),
                  ),
                  child: Text(
                    'ADMIN',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFA5B4FC),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              '${tr("Logged in as")} $currentAdmin',
              style: GoogleFonts.inter(
                color: const Color(0xFF94A3B8),
                fontSize: 11,
              ),
            ),
          ],
        ),
        actions: [
          if (!_isForbidden)
            IconButton(
              icon: _isRefreshing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF6366F1),
                      ),
                    )
                  : const Icon(Icons.refresh_rounded, color: Colors.white70),
              tooltip: tr('Refresh'),
              onPressed: _isRefreshing ? null : () => _loadData(showRefreshing: true),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: const Color(0xFF6366F1),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF94A3B8),
          labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: [
            Tab(
              icon: const Icon(Icons.insights_rounded, size: 18),
              text: tr('Analytics Overview'),
            ),
            Tab(
              icon: (_pendingUpdates != null && _pendingUpdates!.isNotEmpty)
                  ? Badge.count(
                      count: _pendingUpdates!.length,
                      backgroundColor: const Color(0xFFF59E0B),
                      textColor: Colors.black,
                      child: const Icon(Icons.gavel_rounded, size: 18),
                    )
                  : const Icon(Icons.gavel_rounded, size: 18),
              text: tr('Legal Database'),
            ),
            Tab(
              icon: const Icon(Icons.people_alt_rounded, size: 18),
              text: tr('User Directory'),
            ),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF6366F1)),
      );
    }

    if (_isForbidden) {
      return _buildForbiddenView();
    }

    if (_errorMessage != null && _analytics == null) {
      return _buildErrorView();
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildAnalyticsTab(),
        _buildLegalDatabaseTab(),
        _buildUsersTab(),
      ],
    );
  }

  Widget _buildForbiddenView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_rounded,
                color: Color(0xFFEF4444),
                size: 54,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              tr('Administrator Access Required'),
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              tr('This analytics dashboard is restricted to users with the ADMIN role. Your current session does not have administrator privileges.'),
              style: GoogleFonts.inter(
                color: const Color(0xFF94A3B8),
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.login_rounded, color: Colors.white),
              label: Text(
                tr('Log in as Administrator'),
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
              ),
              onPressed: () async {
                await AuthService.logout();
                if (!mounted) return;
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
                if (mounted) {
                  _loadData(showRefreshing: true);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, color: Color(0xFFF59E0B), size: 48),
            const SizedBox(height: 16),
            Text(
              tr('Unable to load analytics'),
              style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? '',
              style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              label: Text(tr('Retry'), style: GoogleFonts.inter(color: Colors.white)),
              onPressed: () => _loadData(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    final a = _analytics!;

    return RefreshIndicator(
      color: const Color(0xFF6366F1),
      backgroundColor: const Color(0xFF1E293B),
      onRefresh: () => _loadData(showRefreshing: true),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status bar strip
            _buildLiveStatusPill(a),
            if (_noticeMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Color(0xFF818CF8), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _noticeMessage!,
                        style: GoogleFonts.inter(color: const Color(0xFFC7D2FE), fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_pendingUpdates != null && _pendingUpdates!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.pending_actions_rounded, color: Color(0xFFF59E0B), size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_pendingUpdates!.length} ${_pendingUpdates!.length == 1 ? "Legal Update" : "Legal Updates"} Awaiting Review',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_pendingUpdates!.first.actName} §${_pendingUpdates!.first.sectionNumber} — ${_pendingUpdates!.first.proposedTitle}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: const Color(0xFFFDE68A),
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: () {
                        _tabController.animateTo(1);
                      },
                      child: Text(
                        tr('Review'),
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Active User definition cards (Suggested layout)
            _buildSectionHeader(tr('User Activity & Growth'), Icons.groups_rounded),
            const SizedBox(height: 10),
            _buildMetricsGrid(a),
            const SizedBox(height: 20),

            // AI Usage section
            _buildSectionHeader(tr('AI Usage & Queries'), Icons.smart_toy_rounded),
            const SizedBox(height: 10),
            _buildAiSection(a),
            const SizedBox(height: 20),

            // Popular Laws & Search Analytics
            _buildSectionHeader(tr('Search & Content Analytics'), Icons.search_rounded),
            const SizedBox(height: 10),
            _buildSearchAndLawsSection(a),
            const SizedBox(height: 20),

            // Most Used Features
            _buildSectionHeader(tr('Feature Usage'), Icons.grid_view_rounded),
            const SizedBox(height: 10),
            _buildFeatureUsageSection(a),
            const SizedBox(height: 20),

            // Database Sync & Backend Status
            _buildSectionHeader(tr('System & Database Status'), Icons.storage_rounded),
            const SizedBox(height: 10),
            _buildSystemStatusSection(a),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // ADMIN TAB 2: Verified Legal Database
  // ─────────────────────────────────────────────────────────

  Widget _buildLegalDatabaseTab() {
    final a = _analytics;
    final syncData = a?.databaseSync ?? {};
    final backendData = a?.backendStatus ?? {};
    final totalActs = syncData['total_acts'] ?? (_acts?.length ?? 0);
    final totalSections = syncData['total_sections'] ?? 0;

    return RefreshIndicator(
      color: const Color(0xFF6366F1),
      backgroundColor: const Color(0xFF1E293B),
      onRefresh: () => _loadData(showRefreshing: true),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.verified_rounded, color: Color(0xFF818CF8), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('Verified Legal Database'),
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          tr('Admin-only database management system'),
                          style: GoogleFonts.inter(
                            color: const Color(0xFF94A3B8),
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      'ADMIN ONLY',
                      style: GoogleFonts.inter(
                        color: const Color(0xFFA5B4FC),
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Database stats
            _buildAdminDbSectionHeader(tr('Database Status'), Icons.storage_rounded),
            const SizedBox(height: 10),
            _buildAdminDbInfoCard([
              _adminDbRow(tr('Sync Version'), 'v${syncData['sync_version'] ?? syncData['server_version'] ?? syncData['version'] ?? '4'}'),
              _adminDbRow(tr('Last Synchronization'), _formatAdminDate((syncData['last_synchronized'] ?? syncData['last_sync_date'] ?? syncData['last_verified_date'] ?? backendData['server_time'])?.toString())),
              _adminDbRow(tr('Total Acts / Laws'), totalActs.toString()),
              _adminDbRow(tr('Total Sections'), totalSections.toString()),
              _adminDbRow(tr('Database Engine'), (syncData['sync_status'] ?? 'SQLite').toString()),
            ]),
            const SizedBox(height: 14),

            // Pending Legal Updates (Review & Approval) - Prioritized for Administrator Action
            _buildAdminDbSectionHeader(tr('Pending Legal Updates'), Icons.verified_user_rounded),
            const SizedBox(height: 10),
            _buildPendingLegalUpdatesSection(),
            const SizedBox(height: 16),

            // Section statuses
            _buildAdminDbSectionHeader(tr('Section Status Breakdown'), Icons.rule_rounded),
            const SizedBox(height: 10),
            _buildStatusBreakdownCards(syncData),
            const SizedBox(height: 16),

            // Acts & Laws
            _buildAdminDbSectionHeader(tr('Acts & Laws'), Icons.gavel_rounded),
            const SizedBox(height: 10),
            _buildActsAndLawsSection(),
            const SizedBox(height: 16),

            // Update pipeline
            _buildAdminDbSectionHeader(tr('Update Pipeline'), Icons.update_rounded),
            const SizedBox(height: 10),
            _buildUpdatePipelineSection(),
            const SizedBox(height: 14),

            // Official source
            _buildAdminDbSectionHeader(tr('Official Sources'), Icons.link_rounded),
            const SizedBox(height: 10),
            _buildAdminDbInfoCard([
              _adminDbRow(tr('Primary Source'), (syncData['primary_source_name'] ?? tr('India Code — Ministry of Law & Justice, Govt. of India')).toString()),
              _adminDbRow(tr('Source URL'), (syncData['primary_source_url'] ?? 'https://www.indiacode.gov.in/').toString()),
              _adminDbRow(tr('Gazette Source'), tr('Official Gazette of India')),
              _adminDbRow(tr('Last Source Check'), _formatAdminDate((backendData['last_source_check'] ?? syncData['last_source_check'] ?? syncData['last_sync_date'])?.toString())),
            ]),
            const SizedBox(height: 14),

            // API/Backend status
            _buildAdminDbSectionHeader(tr('Backend / API Status'), Icons.cloud_rounded),
            const SizedBox(height: 10),
            _buildAdminDbInfoCard([
              _adminDbRow(tr('API Server'), _getApiServerText(backendData)),
              _adminDbRow(tr('API Status'), _getApiStatusText(backendData)),
              _adminDbRow(tr('Administrator'), _getAdminText(backendData)),
              _adminDbRow(tr('Database'), _getDatabaseText(backendData)),
            ]),
            const SizedBox(height: 30),

          ],
        ),
      ),
    );
  }

  Widget _buildStatusBreakdownCards(Map<String, dynamic> syncData) {
    final current = syncData['current_sections'] ?? (syncData['total_sections'] ?? 0);
    final amended = syncData['amended_sections'] ?? 0;
    final historical = syncData['historical_sections'] ?? 0;
    final repealed = syncData['repealed_sections'] ?? 0;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.3,
      children: [
        _dbStatusCard(tr('Current'), '$current', Icons.check_circle_rounded, const Color(0xFF22C55E)),
        _dbStatusCard(tr('Amended'), '$amended', Icons.edit_note_rounded, const Color(0xFF3B82F6)),
        _dbStatusCard(tr('Historical'), '$historical', Icons.history_rounded, const Color(0xFF94A3B8)),
        _dbStatusCard(tr('Repealed'), '$repealed', Icons.remove_circle_rounded, const Color(0xFFF59E0B)),
      ],
    );
  }

  Widget _dbStatusCard(String label, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
                Text(
                  count,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<String> get _availableDomains {
    if (_acts == null) return [];
    final set = <String>{};
    for (final act in _acts!) {
      final d = act.domain.trim();
      if (d.isNotEmpty) {
        set.add(d);
      }
    }
    final list = set.toList()..sort();
    return list;
  }

  List<Law> get _filteredActs {
    if (_acts == null) return [];
    return _acts!.where((act) {
      if (_selectedActStatusFilter != 'ALL') {
        if (act.status.trim().toUpperCase() != _selectedActStatusFilter.toUpperCase()) {
          return false;
        }
      }
      if (_selectedActDomainFilter != 'ALL') {
        if (act.domain.trim().toLowerCase() != _selectedActDomainFilter.toLowerCase()) {
          return false;
        }
      }
      if (_actSearchQuery.trim().isNotEmpty) {
        final q = _actSearchQuery.trim().toLowerCase();
        final nameMatch = act.name.toLowerCase().contains(q);
        final shortMatch = act.shortName.toLowerCase().contains(q);
        final yearMatch = (act.year?.toString() ?? '').contains(q);
        final domainMatch = act.domain.toLowerCase().contains(q);
        if (!nameMatch && !shortMatch && !yearMatch && !domainMatch) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Color _getActStatusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'current':
        return const Color(0xFF22C55E);
      case 'amended':
        return const Color(0xFF3B82F6);
      case 'historical':
        return const Color(0xFF94A3B8);
      case 'repealed':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  Widget _buildActsAndLawsSection() {
    if (_isLoading && _acts == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6366F1)),
        ),
      );
    }

    final filtered = _filteredActs;
    final totalActsCount = _acts?.length ?? 0;
    final domains = _availableDomains;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search bar
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: TextField(
            controller: _actSearchController,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
            cursorColor: const Color(0xFF6366F1),
            decoration: InputDecoration(
              isDense: true,
              hintText: tr('Search Acts & Laws'),
              hintStyle: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 12.5),
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 18),
              suffixIcon: _actSearchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, color: Color(0xFF94A3B8), size: 16),
                      onPressed: () {
                        setState(() {
                          _actSearchController.clear();
                          _actSearchQuery = '';
                        });
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: (val) {
              setState(() {
                _actSearchQuery = val;
              });
            },
          ),
        ),
        const SizedBox(height: 10),

        // Status Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildActFilterChip(
                label: tr('All'),
                isSelected: _selectedActStatusFilter == 'ALL',
                onTap: () => setState(() => _selectedActStatusFilter = 'ALL'),
              ),
              const SizedBox(width: 6),
              _buildActFilterChip(
                label: tr('Current'),
                isSelected: _selectedActStatusFilter == 'CURRENT',
                badgeColor: const Color(0xFF22C55E),
                onTap: () => setState(() => _selectedActStatusFilter = 'CURRENT'),
              ),
              const SizedBox(width: 6),
              _buildActFilterChip(
                label: tr('Amended'),
                isSelected: _selectedActStatusFilter == 'AMENDED',
                badgeColor: const Color(0xFF3B82F6),
                onTap: () => setState(() => _selectedActStatusFilter = 'AMENDED'),
              ),
              const SizedBox(width: 6),
              _buildActFilterChip(
                label: tr('Historical'),
                isSelected: _selectedActStatusFilter == 'HISTORICAL',
                badgeColor: const Color(0xFF94A3B8),
                onTap: () => setState(() => _selectedActStatusFilter = 'HISTORICAL'),
              ),
              const SizedBox(width: 6),
              _buildActFilterChip(
                label: tr('Repealed'),
                isSelected: _selectedActStatusFilter == 'REPEALED',
                badgeColor: const Color(0xFFF59E0B),
                onTap: () => setState(() => _selectedActStatusFilter = 'REPEALED'),
              ),
            ],
          ),
        ),

        // Domain Filter Chips (if any available domains exist)
        if (domains.isNotEmpty) ...[
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildActFilterChip(
                  label: tr('All Domains'),
                  isSelected: _selectedActDomainFilter == 'ALL',
                  isDomain: true,
                  onTap: () => setState(() => _selectedActDomainFilter = 'ALL'),
                ),
                for (final d in domains) ...[
                  const SizedBox(width: 6),
                  _buildActFilterChip(
                    label: d,
                    isSelected: _selectedActDomainFilter.toLowerCase() == d.toLowerCase(),
                    isDomain: true,
                    onTap: () => setState(() => _selectedActDomainFilter = d),
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),

        // Acts Count Summary
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              filtered.length == totalActsCount
                  ? '${filtered.length} ${filtered.length == 1 ? tr("Act") : tr("Acts")}'
                  : '${filtered.length} of $totalActsCount ${tr("Acts")}',
              style: GoogleFonts.inter(
                color: const Color(0xFF94A3B8),
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_actSearchQuery.isNotEmpty || _selectedActStatusFilter != 'ALL' || _selectedActDomainFilter != 'ALL')
              GestureDetector(
                onTap: () {
                  setState(() {
                    _actSearchController.clear();
                    _actSearchQuery = '';
                    _selectedActStatusFilter = 'ALL';
                    _selectedActDomainFilter = 'ALL';
                  });
                },
                child: Text(
                  tr('Reset Filters'),
                  style: GoogleFonts.inter(
                    color: const Color(0xFF818CF8),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),

        // List of Acts
        if (filtered.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              children: [
                const Icon(Icons.search_off_rounded, color: Color(0xFF64748B), size: 36),
                const SizedBox(height: 8),
                Text(
                  tr('No Acts / Laws match the current filters.'),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF94A3B8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final act = filtered[index];
              final statusColor = _getActStatusColor(act.status);

              return Material(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminActDetailScreen(act: act),
                      ),
                    ).then((_) => _loadData());
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Act Title & Status Badge
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                act.name,
                                softWrap: true,
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                  height: 1.25,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                act.status.toUpperCase(),
                                style: GoogleFonts.inter(
                                  color: statusColor,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Domain & Year
                        Row(
                          children: [
                            Text(
                              act.domain.isNotEmpty ? act.domain : tr('General Law'),
                              style: GoogleFonts.inter(
                                color: const Color(0xFF94A3B8),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              ' • ${act.year}',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF64748B),
                                fontSize: 12,
                              ),
                            ),
                            if (act.shortName.isNotEmpty) ...[
                              Text(
                                ' (${act.shortName})',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF64748B),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Section count badge & Arrow
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.verified_rounded, size: 12, color: Color(0xFF818CF8)),
                                  const SizedBox(width: 5),
                                  Text(
                                    '${act.sectionsCount} verified ${act.sectionsCount == 1 ? "section" : "sections"}',
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFFA5B4FC),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: Color(0xFF64748B),
                              size: 20,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildActFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? badgeColor,
    bool isDomain = false,
  }) {
    final activeColor = isDomain ? const Color(0xFF38BDF8) : const Color(0xFF6366F1);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: 0.2)
                : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? activeColor : const Color(0xFF334155),
              width: isSelected ? 1.2 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (badgeColor != null) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: badgeColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: GoogleFonts.inter(
                  color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpdatePipelineSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPipelineStep(1, tr('Official Source Check'), tr('India Code / Official Gazette'), const Color(0xFF6366F1)),
          _buildPipelineConnector(),
          _buildPipelineStep(2, tr('Update Detection'), tr('Compare existing legal records'), const Color(0xFF3B82F6)),
          _buildPipelineConnector(),
          _buildPipelineStep(3, tr('Admin Review'), tr('Manual verification required'), const Color(0xFFF59E0B)),
          _buildPipelineConnector(),
          _buildPipelineStep(4, tr('Publish & Notify'), tr('User notification created on approval'), const Color(0xFF22C55E)),
          _buildPipelineConnector(),
          _buildPipelineStep(5, tr('Mobile Sync'), tr('Incremental database update delivered'), const Color(0xFF14B8A6)),
        ],
      ),
    );
  }

  Widget _buildPendingLegalUpdatesSection() {
    if (_pendingUpdatesError != null) {
      final isAuthError = _pendingUpdatesResult?.isForbidden == true || AuthService.token == null;
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    tr('Unable to Load Pending Legal Updates'),
                    style: GoogleFonts.inter(
                      color: const Color(0xFFFCA5A5),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _pendingUpdatesError!,
              style: GoogleFonts.inter(
                color: const Color(0xFFCBD5E1),
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                if (isAuthError)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.login_rounded, size: 15),
                    label: Text(
                      tr('Sign In as Admin'),
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12.5),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      ).then((_) => _loadData(showRefreshing: true));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                if (isAuthError) const SizedBox(width: 10),
                OutlinedButton.icon(
                  icon: const Icon(Icons.refresh_rounded, size: 15, color: Color(0xFFCBD5E1)),
                  label: Text(
                    tr('Retry'),
                    style: GoogleFonts.inter(color: const Color(0xFFCBD5E1), fontSize: 12.5),
                  ),
                  onPressed: () => _loadData(showRefreshing: true),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF475569)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final updates = _pendingUpdates;

    if (updates == null || updates.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                tr('All legal updates are reviewed and up to date. No pending updates requiring action.'),
                style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 12.5),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              const Icon(Icons.pending_actions_rounded, color: Color(0xFFF59E0B), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${updates.length} ${updates.length == 1 ? "legal update" : "legal updates"} awaiting human review from official government sources',
                  style: GoogleFonts.inter(
                    color: const Color(0xFFFDE68A),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        for (final u in updates) ...[
          _buildPendingUpdateCard(u),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildPendingUpdateCard(AdminPendingUpdateRecord u) {
    final isProcessing = _processingUpdateIds.contains(u.id);
    final notesController = _updateNotesControllers[u.id] ??= TextEditingController(text: u.adminNotes ?? '');

    Color statusColor;
    String statusLabel;
    if (u.isPublished) {
      statusColor = const Color(0xFF10B981);
      statusLabel = tr('PUBLISHED');
    } else if (u.isApproved) {
      statusColor = const Color(0xFF3B82F6);
      statusLabel = tr('APPROVED — READY TO PUBLISH');
    } else if (u.isRejected) {
      statusColor = const Color(0xFFEF4444);
      statusLabel = tr('REJECTED');
    } else {
      statusColor = const Color(0xFFF59E0B);
      statusLabel = tr('PENDING REVIEW');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: u.isApproved ? const Color(0xFF3B82F6).withValues(alpha: 0.6) : const Color(0xFF334155),
          width: u.isApproved ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Act, Section & Status Pill
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            'RECORD #${u.id}',
                            style: GoogleFonts.inter(
                              color: const Color(0xFFA5B4FC),
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            u.actName.isNotEmpty ? u.actName : tr('Indian Law Act'),
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: const Color(0xFF94A3B8),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${u.sectionNumber.startsWith("Section") ? "" : "Section "}${u.sectionNumber}: ${u.proposedTitle}',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.inter(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Metadata Badges (Update Type, Verification, Commencement Status, Effective Date)
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildBadgePill(Icons.category_outlined, u.updateTypeDisplay.isNotEmpty ? u.updateTypeDisplay : u.updateType, const Color(0xFF818CF8)),
              _buildBadgePill(Icons.verified_rounded, u.verificationStatus.toUpperCase(), const Color(0xFF10B981)),
              _buildBadgePill(Icons.gavel_rounded, u.commencementStatus, const Color(0xFF38BDF8)),
              if (u.proposedEffectiveDate != null)
                _buildBadgePill(Icons.event_available_rounded, 'Effective: ${_formatAdminDate(u.proposedEffectiveDate)}', const Color(0xFFA78BFA)),
            ],
          ),
          const SizedBox(height: 14),

          // Source Information with Browser Link
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.account_balance_rounded, color: Color(0xFF818CF8), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        u.sourceName,
                        style: GoogleFonts.inter(
                          color: const Color(0xFFE2E8F0),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (u.sourceUrl.isNotEmpty && u.sourceUrl.startsWith('http'))
                      InkWell(
                        onTap: () async {
                          final uri = Uri.parse(u.sourceUrl);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                tr('Open Source'),
                                style: GoogleFonts.inter(
                                  color: const Color(0xFFA5B4FC),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.open_in_new_rounded, color: Color(0xFFA5B4FC), size: 13),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                if (u.sourcePublicationDate != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${tr("Publication Date")}: ${_formatAdminDate(u.sourcePublicationDate)}',
                    style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Content Comparison: Existing vs Proposed Statutory Text
          _buildComparisonCard(
            title: tr('Proposed Statutory Text'),
            text: u.proposedLegalText,
            color: const Color(0xFF10B981),
            icon: Icons.add_circle_outline_rounded,
          ),
          if (u.existingLegalText.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildComparisonCard(
              title: tr('Existing Legal Text (Previous Version)'),
              text: u.existingLegalText,
              color: const Color(0xFF94A3B8),
              icon: Icons.history_rounded,
            ),
          ],
          const SizedBox(height: 10),

          // Plain-Language Explanation
          if (u.proposedSimpleExplanation.isNotEmpty) ...[
            Text(
              tr('Plain-Language Citizen Explanation:'),
              style: GoogleFonts.inter(
                color: const Color(0xFFCBD5E1),
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              u.proposedSimpleExplanation,
              style: GoogleFonts.inter(
                color: const Color(0xFF94A3B8),
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Punishment Details
          if (u.proposedPunishment.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFF87171), size: 15),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${tr("Penalties")}: ${u.proposedPunishment}',
                      style: GoogleFonts.inter(
                        color: const Color(0xFFFCA5A5),
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Review Notes Input (for Admin)
          if (!u.isPublished) ...[
            TextField(
              controller: notesController,
              enabled: !isProcessing,
              maxLines: 2,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF0F172A),
                hintText: tr('Add review or verification notes...'),
                hintStyle: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 12),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF334155)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF334155)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF6366F1)),
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Action Buttons
          if (u.isPending) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    icon: isProcessing
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_circle_outline_rounded, size: 16),
                    label: Text(
                      tr('Approve Update'),
                      style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                    onPressed: isProcessing ? null : () => _approvePendingUpdate(u),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    side: const BorderSide(color: Color(0xFFEF4444)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: Text(
                    tr('Reject'),
                    style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.bold),
                  ),
                  onPressed: isProcessing ? null : () => _rejectPendingUpdate(u),
                ),
              ],
            ),
          ] else if (u.isApproved) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF60A5FA), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          tr('Approved by Administrator. Ready for canonical publication.'),
                          style: GoogleFonts.inter(
                            color: const Color(0xFF93C5FD),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      icon: isProcessing
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.cloud_upload_rounded, size: 16),
                      label: Text(
                        tr('Publish to Canonical Database & Sync Clients'),
                        style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.bold),
                      ),
                      onPressed: isProcessing ? null : () => _publishApprovedUpdate(u),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (u.isPublished) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.done_all_rounded, color: Color(0xFF34D399), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${tr("Published version")} v${u.approvedVersion ?? 1} • ${tr("Active in Canonical Database")}',
                      style: GoogleFonts.inter(
                        color: const Color(0xFFA7F3D0),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBadgePill(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 5),
          Text(
            text,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonCard({
    required String title,
    required String text,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.inter(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: GoogleFonts.inter(
              color: const Color(0xFFCBD5E1),
              fontSize: 11.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _approvePendingUpdate(AdminPendingUpdateRecord u) async {
    if (_processingUpdateIds.contains(u.id)) return;
    setState(() => _processingUpdateIds.add(u.id));

    final notes = _updateNotesControllers[u.id]?.text.trim() ?? '';
    try {
      final res = await AdminAnalyticsService.approveUpdate(u.id, notes: notes);
      if (!mounted) return;

      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? tr('Update approved. Ready for publication.')),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        await _loadData(showRefreshing: true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['error'] ?? tr('Approval failed.')),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _processingUpdateIds.remove(u.id));
    }
  }

  Future<void> _publishApprovedUpdate(AdminPendingUpdateRecord u) async {
    if (_processingUpdateIds.contains(u.id)) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.cloud_upload_rounded, color: Color(0xFF3B82F6), size: 22),
            const SizedBox(width: 10),
            Text(tr('Publish Legal Update'), style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          tr('Publishing will transactionally update the canonical database, increment sync cursor, archive historical version, and notify all mobile clients.\n\nProceed?'),
          style: GoogleFonts.inter(color: const Color(0xFFCBD5E1), fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('Cancel'), style: GoogleFonts.inter(color: const Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('Publish Now'), style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _processingUpdateIds.add(u.id));
    try {
      final res = await AdminAnalyticsService.publishUpdate(u.id);
      if (!mounted) return;

      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? tr('Update published and synced!')),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        try {
          await LegalDataRepository.syncAll();
        } catch (_) {}
        await _loadData(showRefreshing: true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['error'] ?? tr('Publication failed.')),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _processingUpdateIds.remove(u.id));
    }
  }

  Future<void> _rejectPendingUpdate(AdminPendingUpdateRecord u) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(tr('Reject Legal Update'), style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('Please provide a reason for rejecting this update:'), style: GoogleFonts.inter(color: const Color(0xFFCBD5E1), fontSize: 13)),
            const SizedBox(height: 10),
            TextField(
              controller: reasonController,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: tr('e.g. Unverified gazette circular or errata...'),
                hintStyle: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('Cancel'), style: GoogleFonts.inter(color: const Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () {
              if (reasonController.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: Text(tr('Reject'), style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _processingUpdateIds.add(u.id));
    try {
      final res = await AdminAnalyticsService.rejectUpdate(u.id, reason: reasonController.text.trim());
      if (!mounted) return;

      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? tr('Update rejected.')),
            backgroundColor: const Color(0xFFF59E0B),
            behavior: SnackBarBehavior.floating,
          ),
        );
        await _loadData(showRefreshing: true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['error'] ?? tr('Rejection failed.')),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _processingUpdateIds.remove(u.id));
    }
  }

  Widget _buildPipelineStep(int step, String title, String subtitle, Color color) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Center(
            child: Text(
              step.toString(),
              style: GoogleFonts.inter(color: color, fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12.5)),
              Text(subtitle, style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPipelineConnector() {
    return Padding(
      padding: const EdgeInsets.only(left: 13, top: 4, bottom: 4),
      child: Container(width: 2, height: 12, color: const Color(0xFF334155)),
    );
  }

  Widget _buildAdminDbSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF6366F1), size: 16),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAdminDbInfoCard(List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i < rows.length - 1)
              const Divider(color: Color(0xFF334155), height: 14, thickness: 0.5),
          ],
        ],
      ),
    );
  }

  Widget _adminDbRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(label, style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 11.5)),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(color: const Color(0xFFCBD5E1), fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  String _formatAdminDate(String? raw) {
    if (raw == null || raw.isEmpty) return tr('Not available');
    try {
      final dt = DateTime.parse(raw).toLocal();
      final months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${dt.day} ${months[dt.month]} ${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  Widget _buildLiveStatusPill(AdminAnalyticsData a) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${tr("Currently Active")}: ${a.currentlyActiveUsers} ${tr("users")} (within 15m window)',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '🟢 ${tr("Live")}',
              style: GoogleFonts.inter(
                color: const Color(0xFF10B981),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF6366F1), size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsGrid(AdminAnalyticsData a) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;
        if (isWide) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      label: tr('Total Users'),
                      value: ((_users != null && _users!.isNotEmpty)
                              ? _users!.length
                              : a.totalRegisteredUsers)
                          .toString(),
                      icon: Icons.person_rounded,
                      color: const Color(0xFF6366F1),
                      subtitle: tr('Registered Accounts'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      label: tr('Active Today'),
                      value: a.activeUsersToday.toString(),
                      icon: Icons.today_rounded,
                      color: const Color(0xFF10B981),
                      subtitle: tr('Unique DAU'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      label: tr('Active This Week'),
                      value: a.activeUsersThisWeek.toString(),
                      icon: Icons.calendar_view_week_rounded,
                      color: const Color(0xFF38BDF8),
                      subtitle: tr('7-Day WAU (Distinct)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      label: tr('Active This Month'),
                      value: a.activeUsersThisMonth.toString(),
                      icon: Icons.calendar_month_rounded,
                      color: const Color(0xFFA855F7),
                      subtitle: tr('30-Day MAU (Distinct)'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      label: tr('New Users Today'),
                      value: a.newUsersToday.toString(),
                      icon: Icons.person_add_rounded,
                      color: const Color(0xFFF59E0B),
                      subtitle: '+${a.newUsersThisWeek} ${tr("this week")}',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      label: tr('Active Now'),
                      value: a.currentlyActiveUsers.toString(),
                      icon: Icons.bolt_rounded,
                      color: const Color(0xFFEC4899),
                      subtitle: tr('Active in last 15 min'),
                    ),
                  ),
                ],
              ),
            ],
          );
        }

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    label: tr('Total Users'),
                    value: ((_users != null && _users!.isNotEmpty)
                            ? _users!.length
                            : a.totalRegisteredUsers)
                        .toString(),
                    icon: Icons.person_rounded,
                    color: const Color(0xFF6366F1),
                    subtitle: tr('Registered Accounts'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    label: tr('Active Today'),
                    value: a.activeUsersToday.toString(),
                    icon: Icons.today_rounded,
                    color: const Color(0xFF10B981),
                    subtitle: tr('Unique DAU'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    label: tr('Active This Week'),
                    value: a.activeUsersThisWeek.toString(),
                    icon: Icons.calendar_view_week_rounded,
                    color: const Color(0xFF38BDF8),
                    subtitle: tr('7-Day WAU (Distinct)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    label: tr('Active This Month'),
                    value: a.activeUsersThisMonth.toString(),
                    icon: Icons.calendar_month_rounded,
                    color: const Color(0xFFA855F7),
                    subtitle: tr('30-Day MAU (Distinct)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    label: tr('New Users Today'),
                    value: a.newUsersToday.toString(),
                    icon: Icons.person_add_rounded,
                    color: const Color(0xFFF59E0B),
                    subtitle: '+${a.newUsersThisWeek} ${tr("this week")}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    label: tr('Active Now'),
                    value: a.currentlyActiveUsers.toString(),
                    icon: Icons.bolt_rounded,
                    color: const Color(0xFFEC4899),
                    subtitle: tr('Active in last 15 min'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF94A3B8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 2,
            softWrap: true,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: const Color(0xFF64748B),
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiSection(AdminAnalyticsData a) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildAiStatTile(
                  label: tr('Questions Today'),
                  value: a.aiQuestionsToday.toString(),
                  color: const Color(0xFF6366F1),
                ),
              ),
              Expanded(
                child: _buildAiStatTile(
                  label: tr('This Week'),
                  value: a.aiQuestionsThisWeek.toString(),
                  color: const Color(0xFF38BDF8),
                ),
              ),
              Expanded(
                child: _buildAiStatTile(
                  label: tr('This Month'),
                  value: a.aiQuestionsThisMonth.toString(),
                  color: const Color(0xFFA855F7),
                ),
              ),
            ],
          ),
          const Divider(color: Color(0xFF334155), height: 24),
          Text(
            tr('Popular Question Categories'),
            style: GoogleFonts.inter(
              color: const Color(0xFFE2E8F0),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          if (a.aiCategories.isEmpty)
            Text(
              tr('No category data recorded yet.'),
              style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 12),
            )
          else
            ...a.aiCategories.map((cat) {
              final name = (cat['category'] ?? cat['name'] ?? 'General').toString();
              final count = cat['count'] is int
                  ? (cat['count'] as int)
                  : (int.tryParse(cat['count']?.toString() ?? '0') ?? 0);
              final max = a.totalAiQuestions > 0 ? a.totalAiQuestions : 1;
              final pct = (count / max).clamp(0.05, 1.0);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.inter(
                            color: const Color(0xFFCBD5E1),
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          count.toString(),
                          style: GoogleFonts.inter(
                            color: const Color(0xFF6366F1),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor: const Color(0xFF334155),
                        valueColor: const AlwaysStoppedAnimation(Color(0xFF6366F1)),
                        minHeight: 5,
                      ),
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, color: Color(0xFF10B981), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tr('Privacy Protected: Only aggregate question counts and categories are tracked. Private citizen questions and transcripts are never stored for admin inspection.'),
                    style: GoogleFonts.inter(
                      color: const Color(0xFF94A3B8),
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiStatTile({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: const Color(0xFF94A3B8),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndLawsSection(AdminAnalyticsData a) {
    return Column(
      children: [
        // Most Searched Terms
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tr('Most Searched Terms'),
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${a.totalLawSearches} ${tr("total searches")}',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF6366F1),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const Divider(color: Color(0xFF334155), height: 20),
              if (a.mostSearchedLaws.isEmpty)
                Text(
                  tr('No search logs yet.'),
                  style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 12),
                )
              else
                ...a.mostSearchedLaws.take(5).toList().asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final item = entry.value;
                  final query = (item['query'] ?? item['term'] ?? item['name'] ?? '').toString();
                  final count = item['count'] is int
                      ? item['count'] as int
                      : (int.tryParse(item['count']?.toString() ?? '0') ?? 0);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          alignment: Alignment.center,
                          child: Text(
                            '$idx.',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF64748B),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            query,
                            style: GoogleFonts.inter(
                              color: const Color(0xFFE2E8F0),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF334155),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$count',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF38BDF8),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Most Viewed Legal Sections
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('Most Viewed Legal Sections'),
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Divider(color: Color(0xFF334155), height: 20),
              if (a.mostViewedSections.isEmpty)
                Text(
                  tr('No section views recorded yet.'),
                  style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 12),
                )
              else
                ...a.mostViewedSections.take(5).map((sec) {
                  final title = (sec['section_title'] ?? sec['title'] ?? sec['section'] ?? 'Section').toString();
                  final lawName = (sec['law_name'] ?? sec['code'] ?? '').toString();
                  final count = sec['count'] is int
                      ? (sec['count'] as int)
                      : (sec['views'] is int
                          ? (sec['views'] as int)
                          : (int.tryParse(sec['count']?.toString() ?? sec['views']?.toString() ?? '0') ?? 0));
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.menu_book_rounded, color: Color(0xFFF59E0B), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            lawName.isNotEmpty ? '$title ($lawName)' : title,
                            style: GoogleFonts.inter(
                              color: const Color(0xFFE2E8F0),
                              fontSize: 12.5,
                            ),
                            maxLines: 2,
                            softWrap: true,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$count ${tr("views")}',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF94A3B8),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureUsageSection(AdminAnalyticsData a) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        children: a.mostUsedFeatures.map((feat) {
          final label = (feat['label'] ?? feat['feature'] ?? feat['key'] ?? feat['name'] ?? 'Feature').toString();
          final count = feat['count'] is int
              ? (feat['count'] as int)
              : (int.tryParse(feat['count']?.toString() ?? '0') ?? 0);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF6366F1),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        color: const Color(0xFFE2E8F0),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Text(
                    count.toString(),
                    style: GoogleFonts.inter(
                      color: const Color(0xFF6366F1),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSystemStatusSection(AdminAnalyticsData a) {
    final sync = a.databaseSync;
    final backend = a.backendStatus;

    final backendStatusText = (backend["status"] ?? backend["api_status"] ?? "operational").toString();
    final databaseEngineText = (backend["database"] ?? "SQLite Database Engine").toString();
    final aiServiceText = (backend["ai_service"] ?? backend["administrator"] ?? "Configured").toString();
    final syncVersionText = (sync["server_version"] ?? sync["version"] ?? "1.1.0").toString();
    final categoriesCount = (sync["total_categories"] ?? sync["total_acts"] ?? 5).toString();
    final lawsCount = (sync["total_laws"] ?? sync["total_acts"] ?? 5).toString();
    final sectionsCount = (sync["total_sections"] ?? 1240).toString();
    final sourceName = (sync["primary_source_name"] ?? sync["sync_status"] ?? "India Code (indiacode.gov.in)").toString();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cloud_done_rounded, color: Color(0xFF10B981), size: 18),
              const SizedBox(width: 8),
              Text(
                '${tr("Backend Status")}: $backendStatusText',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${tr("Database Engine")}: $databaseEngineText',
            style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 12),
          ),
          Text(
            '${tr("AI Service Engine")}: OpenAI GPT-4o-mini ($aiServiceText)',
            style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 12),
          ),
          const Divider(color: Color(0xFF334155), height: 20),
          Text(
            '${tr("Legal Database Sync Version")}: v$syncVersionText',
            style: GoogleFonts.inter(
              color: const Color(0xFFE2E8F0),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${tr("Database Contents")}: $categoriesCount ${tr("Categories")} · $lawsCount ${tr("Laws")} · $sectionsCount ${tr("Legal Sections")}',
            style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            '${tr("Primary Official Source")}: $sourceName',
            style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 11),
          ),
        ],
      ),
    );
  }

  String _getApiServerText(Map<String, dynamic> data) {
    final status = _adminStatus;
    final val = status?['apiServer'] ?? status?['activeServer'] ?? data['apiServer'] ?? data['api_server'] ?? data['active_server'] ?? data['activeServer'];
    if (val != null && val.toString().isNotEmpty && val.toString() != '-') {
      return val.toString();
    }
    return _errorMessage != null ? tr('Offline') : 'https://dinesh03.pythonanywhere.com/api';
  }

  String _getApiStatusText(Map<String, dynamic> data) {
    final status = _adminStatus;
    final val = status?['apiStatus'] ?? data['apiStatus'] ?? data['api_status'] ?? data['status'];
    if (val != null && val.toString().isNotEmpty && val.toString() != '-') {
      return val.toString();
    }
    return _errorMessage != null ? tr('Unavailable') : tr('Healthy');
  }

  String _getAdminText(Map<String, dynamic> data) {
    final status = _adminStatus;
    final val = status?['administrator'] ?? data['administrator'];
    if (val != null && val.toString().isNotEmpty && val.toString() != '-') {
      return val.toString();
    }
    return AuthService.currentUsername.value ?? 'Admin';
  }

  String _getDatabaseText(Map<String, dynamic> data) {
    final status = _adminStatus;
    final val = status?['database'] ?? data['database'];
    if (val != null && val.toString().isNotEmpty && val.toString() != '-') {
      return val.toString();
    }
    return 'connected';
  }

  String _formatUserDate(String? raw) {
    if (raw == null || raw.isEmpty) return tr('Not available');
    try {
      final dt = DateTime.parse(raw).toLocal();
      final months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${dt.day} ${months[dt.month]} ${dt.year}';
    } catch (_) {
      return raw.split('T').first;
    }
  }

  String _formatUserActivity(String? raw) {
    if (raw == null || raw.isEmpty) return tr('Never');
    try {
      final dt = DateTime.parse(raw).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 2) {
        return tr('Active Now');
      } else if (diff.inMinutes < 60) {
        return '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24 && dt.day == now.day) {
        return tr('Today');
      } else if (diff.inDays == 1 || (diff.inHours < 48 && dt.day == now.day - 1)) {
        return tr('Yesterday');
      }
      final months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${dt.day} ${months[dt.month]} ${dt.year}';
    } catch (_) {
      return raw.split('T').first;
    }
  }

  Widget _buildUsersTab() {
    if (_userErrorMessage != null && (_users == null || _users!.isEmpty)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.people_outline_rounded, color: Color(0xFFF59E0B), size: 48),
              const SizedBox(height: 16),
              Text(
                tr('Unable to load User Directory'),
                style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _userErrorMessage!,
                style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                label: Text(tr('Retry'), style: GoogleFonts.inter(color: Colors.white)),
                onPressed: () => _loadData(showRefreshing: true),
              ),
            ],
          ),
        ),
      );
    }

    final allUsers = _users ?? [];
    final citizens = allUsers.where((u) => u.role.toUpperCase() == 'USER').toList();
    final admins = allUsers.where((u) => u.role.toUpperCase() == 'ADMIN').toList();

    final allUsersCount = allUsers.isNotEmpty
        ? allUsers.length
        : (_usersResult?.totalAccounts ?? _usersResult?.total ?? 0);
    final citizensCount = allUsers.isNotEmpty
        ? citizens.length
        : (_usersResult?.normalUsers ?? 0);
    final adminsCount = allUsers.isNotEmpty
        ? admins.length
        : (_usersResult?.adminUsers ?? 0);

    // Filter
    final query = _userSearchQuery.trim().toLowerCase();
    final filteredUsers = allUsers.where((u) {
      if (query.isNotEmpty) {
        final matchesName = u.name.toLowerCase().contains(query);
        final matchesUser = u.username.toLowerCase().contains(query);
        final matchesEmail = u.email.toLowerCase().contains(query);
        if (!matchesName && !matchesUser && !matchesEmail) return false;
      }
      if (_selectedRoleFilter == 'USER') {
        return u.role.toUpperCase() == 'USER';
      } else if (_selectedRoleFilter == 'ADMIN') {
        return u.role.toUpperCase() == 'ADMIN';
      } else if (_selectedRoleFilter == 'ACTIVE') {
        return u.status == 'Active Now' || u.status == 'Active Today';
      }
      return true;
    }).toList();

    return RefreshIndicator(
      color: const Color(0xFF6366F1),
      backgroundColor: const Color(0xFF1E293B),
      onRefresh: () => _loadData(showRefreshing: true),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header summary card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.people_alt_rounded, color: Color(0xFF818CF8), size: 20),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          tr('User Directory'),
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        '${tr("Total Users")}: $allUsersCount',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFA5B4FC),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '$citizensCount ${tr("Registered Citizens / Users")} · $adminsCount ${adminsCount == 1 ? tr("Admin Account") : tr("Admin Accounts")}',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Search bar
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() => _userSearchQuery = val);
              },
              style: GoogleFonts.inter(color: Colors.white, fontSize: 13.5),
              decoration: InputDecoration(
                hintText: tr('Search users by name or email...'),
                hintStyle: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                suffixIcon: _userSearchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: Color(0xFF94A3B8), size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _userSearchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _userFilterChip('ALL', '${tr("All Users")} ($allUsersCount)'),
                const SizedBox(width: 8),
                _userFilterChip('USER', '${tr("Citizens")} ($citizensCount)'),
                const SizedBox(width: 8),
                _userFilterChip('ADMIN', '${tr("Admins")} ($adminsCount)'),
                const SizedBox(width: 8),
                _userFilterChip('ACTIVE', tr('Active Now / Today')),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Users count banner or empty
          if (filteredUsers.isEmpty)
            Container(
              padding: const EdgeInsets.all(28),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Icon(Icons.person_search_rounded, color: Color(0xFF64748B), size: 42),
                  const SizedBox(height: 12),
                  Text(
                    _userSearchQuery.isNotEmpty
                        ? tr('No users matching search.')
                        : tr('No registered users found.'),
                    style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 14),
                  ),
                ],
              ),
            )
          else
            ...filteredUsers.map((u) => _buildUserCard(u)),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _userFilterChip(String key, String label) {
    final isSelected = _selectedRoleFilter == key;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedRoleFilter = key);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF334155),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: isSelected ? Colors.white : const Color(0xFF94A3B8),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(AdminUserData u) {
    final currentAdmin = AuthService.currentUsername.value ?? 'Admin';
    final isCurrentAdmin = u.username.trim().toLowerCase() == currentAdmin.trim().toLowerCase();
    final isDeleting = _deletingUserIds.contains(u.id);

    final isAdmin = u.role.toUpperCase() == 'ADMIN' || u.isAdmin;
    final isActiveNow = u.status == 'Active Now';
    final isActiveToday = u.status == 'Active Today';

    Color statusColor = const Color(0xFF64748B);
    if (isActiveNow) {
      statusColor = const Color(0xFF10B981);
    } else if (isActiveToday) {
      statusColor = const Color(0xFF06B6D4);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isAdmin ? const Color(0xFF6366F1).withValues(alpha: 0.5) : const Color(0xFF334155),
          width: isAdmin ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: isAdmin
                            ? const Color(0xFF6366F1).withValues(alpha: 0.15)
                            : const Color(0xFF334155).withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isAdmin ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
                        color: isAdmin ? const Color(0xFF818CF8) : const Color(0xFF94A3B8),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        u.name.isNotEmpty && u.name != u.username ? '${u.name} (${u.username})' : u.username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      u.status,
                      style: GoogleFonts.inter(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: isAdmin
                          ? const Color(0xFF6366F1).withValues(alpha: 0.2)
                          : const Color(0xFF334155),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      u.role,
                      style: GoogleFonts.inter(
                        color: isAdmin ? const Color(0xFFA5B4FC) : const Color(0xFF94A3B8),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${tr("Email")}: ${u.email.isNotEmpty ? u.email : tr("Not provided")}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 12),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Text(
                      '${tr("Registered")}: ${_formatUserDate(u.registrationDate)}',
                      style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 11),
                    ),
                    Text(
                      '${tr("Last Active")}: ${_formatUserActivity(u.lastActiveAt ?? u.lastLoginAt)}',
                      style: GoogleFonts.inter(
                        color: isActiveNow || isActiveToday ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isCurrentAdmin)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    tr('Current Account'),
                    style: GoogleFonts.inter(
                      color: const Color(0xFFA5B4FC),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isDeleting)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      )
                    else
                      InkWell(
                        onTap: () => _confirmAndDeleteUser(u),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.35)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.delete_outline_rounded, color: Color(0xFFF87171), size: 14),
                              const SizedBox(width: 4),
                              Text(
                                tr('Delete'),
                                style: GoogleFonts.inter(
                                  color: const Color(0xFFF87171),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
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
        ],
      ),
    );
  }
}

