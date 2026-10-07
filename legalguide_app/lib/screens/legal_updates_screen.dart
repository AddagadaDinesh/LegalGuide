import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../localization/app_strings.dart';
import '../models/legal_update.dart';
import '../services/legal_update_service.dart';
import '../services/locale_service.dart';
import '../theme/app_theme.dart';

/// User-facing screen: shows verified, published legal updates.
/// Does NOT expose any admin terminology (pending, pipeline, verification, etc.)
class LegalUpdatesScreen extends StatefulWidget {
  const LegalUpdatesScreen({super.key});

  @override
  State<LegalUpdatesScreen> createState() => _LegalUpdatesScreenState();
}

class _LegalUpdatesScreenState extends State<LegalUpdatesScreen> {
  List<LegalUpdate> _updates = [];
  bool _loading = true;
  String _lastSync = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool forceSync = false}) async {
    setState(() => _loading = true);
    final updates = await LegalUpdateService.loadUpdates(forceSync: forceSync);
    final lastSync = await LegalUpdateService.getFormattedLastSync();
    if (!mounted) return;
    setState(() {
      _updates = updates;
      _lastSync = lastSync;
      _loading = false;
    });
  }

  Future<void> _markAllRead() async {
    await LegalUpdateService.markAllAsRead();
    if (!mounted) return;
    setState(() {
      for (final u in _updates) {
        u.isRead = true;
      }
    });
  }

  Future<void> _openUpdate(LegalUpdate update) async {
    if (!update.isRead) {
      await LegalUpdateService.markAsRead(update.id);
      if (!mounted) return;
      setState(() => update.isRead = true);
    }
    if (!mounted) return;
    _showUpdateDetail(update);
  }

  void _showUpdateDetail(LegalUpdate update) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _UpdateDetailSheet(update: update),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LocaleService.language,
      builder: (context, _, _) {
        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Row(
              children: [
                const Icon(Icons.campaign_rounded, color: AppColors.accent, size: 20),
                const SizedBox(width: 8),
                Text(
                  tr('Legal Updates'),
                  style: GoogleFonts.outfit(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            actions: [
              if (_updates.any((u) => !u.isRead))
                TextButton(
                  onPressed: _markAllRead,
                  child: Text(
                    tr('Mark all read'),
                    style: GoogleFonts.inter(color: AppColors.accent, fontSize: 12),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: AppColors.accent),
                onPressed: () => _load(forceSync: true),
                tooltip: tr('Check for updates'),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => _load(forceSync: true),
            color: AppColors.accent,
            backgroundColor: AppColors.surface,
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                : _updates.isEmpty
                    ? _buildEmpty()
                    : _buildList(),
          ),
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 48),
            ),
            const SizedBox(height: 20),
            Text(
              tr('Legal Information Up to Date'),
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tr('Your LegalGuide database is synchronized.'),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
            ),
            if (_lastSync.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '${tr("Last synchronized")}: $_lastSync',
                style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11.5),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    final unreadCount = _updates.where((u) => !u.isRead).length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Summary banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: unreadCount > 0
                ? AppColors.accent.withValues(alpha: 0.1)
                : AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: unreadCount > 0
                  ? AppColors.accent.withValues(alpha: 0.3)
                  : AppColors.success.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                unreadCount > 0 ? Icons.campaign_rounded : Icons.check_circle_rounded,
                color: unreadCount > 0 ? AppColors.accent : AppColors.success,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      unreadCount > 0
                          ? '${tr("New verified legal updates")}: $unreadCount'
                          : tr('Legal Information Up to Date'),
                      style: GoogleFonts.inter(
                        color: unreadCount > 0 ? AppColors.accent : AppColors.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                    if (_lastSync.isNotEmpty)
                      Text(
                        '${tr("Last synchronized")}: $_lastSync',
                        style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ..._updates.map((update) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _UpdateCard(update: update, onTap: () => _openUpdate(update)),
            )),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// Update Card Widget
// ─────────────────────────────────────────────────────────

class _UpdateCard extends StatelessWidget {
  final LegalUpdate update;
  final VoidCallback onTap;

  const _UpdateCard({required this.update, required this.onTap});

  Color get _typeColor {
    switch (update.updateType) {
      case 'amendment':
        return const Color(0xFF3B82F6);
      case 'new_section':
        return AppColors.success;
      case 'repeal':
        return AppColors.warning;
      case 'penalty_change':
        return const Color(0xFFF59E0B);
      case 'new_act':
        return const Color(0xFF8B5CF6);
      case 'rule_change':
        return const Color(0xFF14B8A6);
      default:
        return AppColors.accent;
    }
  }

  IconData get _typeIcon {
    switch (update.updateType) {
      case 'amendment':
        return Icons.edit_note_rounded;
      case 'new_section':
        return Icons.add_circle_rounded;
      case 'repeal':
        return Icons.remove_circle_rounded;
      case 'penalty_change':
        return Icons.gavel_rounded;
      case 'new_act':
        return Icons.description_rounded;
      case 'rule_change':
        return Icons.rule_rounded;
      default:
        return Icons.update_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: update.isRead
                  ? AppColors.border
                  : AppColors.accent.withValues(alpha: 0.4),
              width: update.isRead ? 1 : 1.5,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: _typeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_typeIcon, color: _typeColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            update.title,
                            style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontWeight: update.isRead ? FontWeight.w500 : FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (!update.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      update.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 11.5,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: _typeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            tr(update.updateTypeDisplay),
                            style: GoogleFonts.inter(
                              color: _typeColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          update.formattedPublishedDate,
                          style: GoogleFonts.inter(
                            color: AppColors.textMuted,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Update Detail Bottom Sheet
// ─────────────────────────────────────────────────────────

class _UpdateDetailSheet extends StatelessWidget {
  final LegalUpdate update;

  const _UpdateDetailSheet({required this.update});

  Color get _typeColor {
    switch (update.updateType) {
      case 'amendment':
        return const Color(0xFF3B82F6);
      case 'new_section':
        return AppColors.success;
      case 'repeal':
        return AppColors.warning;
      case 'penalty_change':
        return const Color(0xFFF59E0B);
      case 'new_act':
        return const Color(0xFF8B5CF6);
      default:
        return AppColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 6),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _typeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tr(update.updateTypeDisplay),
                            style: GoogleFonts.inter(
                              color: _typeColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified_rounded, color: AppColors.success, size: 11),
                              const SizedBox(width: 3),
                              Text(
                                tr('Verified'),
                                style: GoogleFonts.inter(
                                  color: AppColors.success,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      update.title,
                      style: GoogleFonts.outfit(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      update.description,
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Info grid
                    _DetailCard(children: [
                      if (update.affectedLawShortName.isNotEmpty || update.affectedLawName.isNotEmpty)
                        _DetailRow(
                          label: tr('Law'),
                          value: update.affectedLawShortName.isNotEmpty
                              ? update.affectedLawShortName
                              : update.affectedLawName,
                        ),
                      if (update.affectedSection.isNotEmpty)
                        _DetailRow(label: tr('Section'), value: 'Section ${update.affectedSection}'),
                      if (update.newVersion != null)
                        _DetailRow(
                          label: tr('Version'),
                          value: update.oldVersion != null
                              ? 'v${update.oldVersion} → v${update.newVersion}'
                              : 'v${update.newVersion}',
                        ),
                      if (update.effectiveDate != null && update.effectiveDate!.isNotEmpty)
                        _DetailRow(label: tr('Effective Date'), value: update.formattedEffectiveDate),
                      _DetailRow(label: tr('Updated'), value: update.formattedPublishedDate),
                      if (update.lastVerifiedAt != null && update.lastVerifiedAt!.isNotEmpty)
                        _DetailRow(label: tr('Verified'), value: update.lastVerifiedAt!),
                    ]),

                    const SizedBox(height: 14),

                    // Source
                    _DetailCard(children: [
                      _DetailRow(label: tr('Source'), value: update.officialSourceName),
                    ]),

                    const SizedBox(height: 16),

                    // Disclaimer
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.bg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded, color: AppColors.textMuted, size: 14),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              tr('This update has been verified by LegalGuide and sourced from official government publications.'),
                              style: GoogleFonts.inter(
                                color: AppColors.textMuted,
                                fontSize: 11,
                                height: 1.4,
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
            ],
          ),
        );
      },
    );
  }
}

class _DetailCard extends StatelessWidget {
  final List<Widget> children;
  const _DetailCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              const Divider(color: AppColors.border, height: 16, thickness: 0.5),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11.5),
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
    );
  }
}
