import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../localization/app_strings.dart';
import '../models/legal_section.dart';
import '../services/sqlite_legal_db.dart';

class AdminSectionDetailScreen extends StatefulWidget {
  final LegalSection section;
  final String actName;

  const AdminSectionDetailScreen({
    super.key,
    required this.section,
    required this.actName,
  });

  @override
  State<AdminSectionDetailScreen> createState() => _AdminSectionDetailScreenState();
}

class _AdminSectionDetailScreenState extends State<AdminSectionDetailScreen> {
  late LegalSection _currentSection;

  @override
  void initState() {
    super.initState();
    _currentSection = widget.section;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'current':
        return const Color(0xFF22C55E);
      case 'amended':
        return const Color(0xFF3B82F6);
      case 'historical':
        return const Color(0xFF94A3B8);
      case 'repealed':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF818CF8);
    }
  }

  Future<void> _toggleVisualEnabled(bool value) async {
    final updated = _currentSection.copyWith(isVisualIllustrative: value);
    setState(() => _currentSection = updated);
    await SqliteLegalDb.updateSectionMedia(
      sectionId: updated.id,
      visualImageUrl: updated.visualImageUrl,
      visualCaption: updated.visualCaption,
      visualAltText: updated.visualAltText,
      isVisualIllustrative: value,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? tr('Visual illustration enabled for users.')
                : tr('Visual illustration disabled for users.'),
          ),
          backgroundColor: value ? const Color(0xFF22C55E) : const Color(0xFFF59E0B),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _editVisualDialog() async {
    final urlController = TextEditingController(text: _currentSection.visualImageUrl);
    final captionController = TextEditingController(text: _currentSection.visualCaption);
    final altTextController = TextEditingController(text: _currentSection.visualAltText);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          tr('Edit Visual Example & Media'),
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('Image Asset Path or Web URL:'),
                style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 12),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: urlController,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'assets/illustrations/example.jpg or https://...',
                  hintStyle: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 12),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                tr('Visual Caption:'),
                style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 12),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: captionController,
                maxLines: 2,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Enter short descriptive explanation...',
                  hintStyle: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 12),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                tr('Alt Text (Accessibility):'),
                style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 12),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: altTextController,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Descriptive text for accessibility...',
                  hintStyle: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 12),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('Cancel'), style: const TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF38BDF8)),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('Save Changes'), style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (result == true) {
      final updated = _currentSection.copyWith(
        visualImageUrl: urlController.text.trim(),
        visualCaption: captionController.text.trim(),
        visualAltText: altTextController.text.trim(),
        isVisualIllustrative: true,
      );
      setState(() => _currentSection = updated);
      await SqliteLegalDb.updateSectionMedia(
        sectionId: updated.id,
        visualImageUrl: updated.visualImageUrl,
        visualCaption: updated.visualCaption,
        visualAltText: updated.visualAltText,
        isVisualIllustrative: true,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('Visual example successfully updated!')),
            backgroundColor: const Color(0xFF22C55E),
          ),
        );
      }
    }
  }

  Future<void> _removeVisual() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(tr('Remove Visual Example'), style: GoogleFonts.outfit(color: Colors.white)),
        content: Text(
          tr('Are you sure you want to remove the visual illustration for this provision?'),
          style: GoogleFonts.inter(color: const Color(0xFFCBD5E1), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('Cancel'), style: const TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('Remove'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final updated = _currentSection.copyWith(
        visualImageUrl: '',
        visualCaption: '',
        visualAltText: '',
      );
      setState(() => _currentSection = updated);
      await SqliteLegalDb.updateSectionMedia(
        sectionId: updated.id,
        visualImageUrl: '',
        visualCaption: '',
        visualAltText: '',
        isVisualIllustrative: false,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('Visual example removed.')),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _showZoomPreview(BuildContext context, String imageUri) {
    final isAsset = imageUri.startsWith('assets/');
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.8,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: isAsset
                    ? Image.asset(imageUri, fit: BoxFit.contain)
                    : Image.network(imageUri, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: CircleAvatar(
                backgroundColor: Colors.black.withValues(alpha: 0.7),
                radius: 18,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaManagementCard(BuildContext context) {
    final s = _currentSection;
    final hasImg = s.visualImageUrl.trim().isNotEmpty;
    final isAsset = s.visualImageUrl.startsWith('assets/');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  hasImg ? tr('Active Visual Illustration') : tr('No Visual Illustration Attached'),
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              if (hasImg)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      s.isVisualIllustrative ? tr('Enabled') : tr('Disabled'),
                      style: GoogleFonts.inter(
                        color: s.isVisualIllustrative ? const Color(0xFF22C55E) : const Color(0xFF94A3B8),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Switch(
                      value: s.isVisualIllustrative,
                      activeThumbColor: const Color(0xFF38BDF8),
                      onChanged: _toggleVisualEnabled,
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),

          if (hasImg) ...[
            GestureDetector(
              onTap: () => _showZoomPreview(context, s.visualImageUrl),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 180,
                  width: double.infinity,
                  color: const Color(0xFF0F172A),
                  child: isAsset
                      ? Image.asset(s.visualImageUrl, fit: BoxFit.contain)
                      : Image.network(
                          s.visualImageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Center(
                            child: Icon(Icons.broken_image_rounded, color: Color(0xFF64748B)),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Text(
                tr('Illustrative example for educational purposes — not an actual case.'),
                style: GoogleFonts.inter(
                  color: const Color(0xFF94A3B8),
                  fontSize: 10.5,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            if (s.visualCaption.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                '${tr("Caption:")} ${s.visualCaption}',
                style: GoogleFonts.inter(color: const Color(0xFFCBD5E1), fontSize: 12),
              ),
            ],
            if (s.visualAltText.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '${tr("Alt Text:")} ${s.visualAltText}',
                style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 11.5),
              ),
            ],
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF334155), style: BorderStyle.solid),
              ),
              child: Center(
                child: Text(
                  tr('This legal provision currently displays text-only educational examples. You can attach a high-resolution illustration or infographic.'),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 12),
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF38BDF8),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _editVisualDialog,
                  icon: Icon(hasImg ? Icons.edit_rounded : Icons.add_photo_alternate_rounded, size: 16, color: const Color(0xFF0F172A)),
                  label: Text(
                    hasImg ? tr('Edit Visual') : tr('Add Visual Example'),
                    style: GoogleFonts.inter(color: const Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
              if (hasImg) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: tr('Preview'),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Color(0xFF334155)),
                    ),
                  ),
                  icon: const Icon(Icons.visibility_rounded, color: Color(0xFF38BDF8), size: 18),
                  onPressed: () => _showZoomPreview(context, s.visualImageUrl),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: tr('Remove'),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Color(0xFFEF4444)),
                    ),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 18),
                  onPressed: _removeVisual,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final section = _currentSection;
    final statusColor = _getStatusColor(section.status);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${section.sectionNumber} - ${tr("Section Details")}',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: statusColor.withValues(alpha: 0.5)),
            ),
            child: Center(
              child: Text(
                section.status.toUpperCase(),
                style: GoogleFonts.inter(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Act reference card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('Parent Act / Law'),
                    style: GoogleFonts.inter(
                      color: const Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.actName,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Identity & Version Card
            _buildSectionHeader(tr('Provision Identity & Versioning'), Icons.fingerprint_rounded),
            const SizedBox(height: 8),
            _buildInfoCard([
              _infoRow(tr('Canonical Key'), section.provisionKey.isNotEmpty ? section.provisionKey : 'N/A'),
              _infoRow(tr('Section Number'), section.sectionNumber),
              _infoRow(tr('Title'), section.title),
              _infoRow(tr('Content Version'), 'v${section.version}'),
              if (section.previousVersionRef != null && section.previousVersionRef!.isNotEmpty)
                _infoRow(tr('Previous Version'), section.previousVersionRef!),
              if (section.effectiveDate != null)
                _infoRow(tr('Effective Date'), section.effectiveDate!),
              if (section.updatedAt != null)
                _infoRow(tr('Last Updated'), section.updatedAt!),
            ]),
            const SizedBox(height: 16),

            // Statutory Text
            _buildSectionHeader(
              section.isVerifiedStatutoryText
                  ? tr('Official Statutory Legal Text')
                  : tr('Plain-Language Legal Explanation'),
              Icons.gavel_rounded,
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Text(
                section.legalText,
                style: GoogleFonts.inter(
                  color: const Color(0xFFE2E8F0),
                  fontSize: 13.5,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Simple Explanation
            _buildSectionHeader(tr('Simple English Explanation'), Icons.translate_rounded),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
              ),
              child: Text(
                section.simpleExplanation,
                style: GoogleFonts.inter(
                  color: const Color(0xFFBAE6FD),
                  fontSize: 13.5,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Purpose
            if (section.purpose.isNotEmpty) ...[
              _buildSectionHeader(tr('Purpose & Intent'), Icons.lightbulb_outline_rounded),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Text(
                  section.purpose,
                  style: GoogleFonts.inter(
                    color: const Color(0xFFCBD5E1),
                    fontSize: 13.5,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Quick Answer
            if (section.quickAnswer.isNotEmpty) ...[
              _buildSectionHeader(tr('⚡ Quick Answer for Citizens'), Icons.bolt_rounded),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                ),
                child: Text(
                  section.quickAnswer,
                  style: GoogleFonts.inter(
                    color: const Color(0xFFFDE68A),
                    fontSize: 13.5,
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Real-Life Example
            if (section.hasRealLifeExample) ...[
              _buildSectionHeader(tr('💡 Real-Life Educational Example'), Icons.lightbulb_rounded),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (section.exampleSituation.isNotEmpty) ...[
                      Text(
                        tr('Situation:'),
                        style: GoogleFonts.inter(
                          color: const Color(0xFFF59E0B),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        section.exampleSituation,
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 13, height: 1.45),
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (section.exampleExplanation.isNotEmpty) ...[
                      Text(
                        tr('How the law applies:'),
                        style: GoogleFonts.inter(
                          color: const Color(0xFFF59E0B),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        section.exampleExplanation,
                        style: GoogleFonts.inter(color: const Color(0xFFCBD5E1), fontSize: 13, height: 1.45),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 🖼️ Examples & Media Management Section (Admin Feature)
            _buildSectionHeader(tr('🖼️ Examples & Media Management'), Icons.photo_library_rounded),
            const SizedBox(height: 8),
            _buildMediaManagementCard(context),
            const SizedBox(height: 16),

            // What You Should Do
            if (section.whatYouShouldDoList.isNotEmpty) ...[
              _buildSectionHeader(tr('📋 What You Should Do'), Icons.check_circle_outline_rounded),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF06B6D4).withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final item in section.whatYouShouldDoList)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          '• $item',
                          style: GoogleFonts.inter(color: const Color(0xFFE2E8F0), fontSize: 13),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Step-by-step Flow
            if (section.hasSteps) ...[
              _buildSectionHeader(tr('Procedural Steps Flow'), Icons.linear_scale_rounded),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final step in section.exampleStepsList)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          '${step.order}. ${step.title}: ${step.description}',
                          style: GoogleFonts.inter(color: const Color(0xFFE2E8F0), fontSize: 12.5),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Punishment / Penalty / Consequences
            if (section.punishment.isNotEmpty) ...[
              _buildSectionHeader(
                section.consequencesType == 'order' ? tr('Court Orders & Enforcement') : tr('Punishment / Penalty'),
                section.consequencesType == 'order' ? Icons.gavel_rounded : Icons.shield_outlined,
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                ),
                child: Text(
                  section.punishment,
                  style: GoogleFonts.inter(
                    color: const Color(0xFFFCA5A5),
                    fontSize: 13.5,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Official Source Info
            _buildSectionHeader(tr('Official Source Verification'), Icons.verified_user_rounded),
            const SizedBox(height: 8),
            _buildInfoCard([
              _infoRow(tr('Official Source'), section.sourceName.isNotEmpty ? section.sourceName : 'India Code — Ministry of Law & Justice, Govt. of India'),
              _infoRow(tr('Source Type'), section.sourceType),
              _infoRow(tr('Source URL'), section.source.isNotEmpty ? section.source : 'https://www.indiacode.gov.in/'),
              _infoRow(tr('Last Verified Date'), section.lastVerified ?? tr('Not verified yet')),
            ]),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF818CF8), size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 14.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(List<Widget> rows) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        children: rows,
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF334155), width: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: const Color(0xFF94A3B8),
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
