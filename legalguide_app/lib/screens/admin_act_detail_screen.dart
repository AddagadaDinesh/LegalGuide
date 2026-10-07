import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../localization/app_strings.dart';
import '../models/law.dart';
import '../models/legal_section.dart';
import '../repositories/legal_data_repository.dart';
import 'admin_section_detail_screen.dart';

class AdminActDetailScreen extends StatefulWidget {
  final Law act;

  const AdminActDetailScreen({super.key, required this.act});

  @override
  State<AdminActDetailScreen> createState() => _AdminActDetailScreenState();
}

class _AdminActDetailScreenState extends State<AdminActDetailScreen> {
  bool _isLoading = true;
  List<LegalSection> _sections = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSections();
  }

  Future<void> _loadSections() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final allSections = await LegalDataRepository.loadSections(lawId: widget.act.id);
      if (mounted) {
        setState(() {
          _sections = allSections;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
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

  @override
  Widget build(BuildContext context) {
    final act = widget.act;
    final statusColor = _getStatusColor(act.status);

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
          act.shortName.isNotEmpty ? act.shortName : act.name,
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
                act.status.toUpperCase(),
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
            // Act Header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.menu_book_rounded, color: Color(0xFF818CF8), size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              act.name,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                height: 1.3,
                              ),
                            ),
                            if (act.shortName.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                act.shortName,
                                style: GoogleFonts.inter(
                                  color: const Color(0xFFA5B4FC),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (act.description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      act.description,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF94A3B8),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Act Statutory Metadata
            _buildSectionHeader(tr('Act Overview'), Icons.info_outline_rounded),
            const SizedBox(height: 8),
            _buildInfoCard([
              _infoRow(tr('Act Name'), act.name),
              _infoRow(tr('Short Name / Abbr'), act.shortName.isNotEmpty ? act.shortName : tr('None')),
              _infoRow(tr('Year'), act.year != null ? act.year.toString() : tr('Not specified')),
              _infoRow(tr('Legal Domain'), act.domain.isNotEmpty ? act.domain : tr('General')),
              _infoRow(tr('Jurisdiction'), tr('Central / India')),
              _infoRow(tr('Status'), act.status.toUpperCase()),
              _infoRow(tr('Effective Date'), act.updatedAt != null ? _formatDate(act.updatedAt!) : tr('Current')),
              _infoRow(tr('Last Verified'), act.lastVerified != null ? _formatDate(act.lastVerified!) : tr('Current / Verified')),
              _infoRow(tr('Official Source'), act.sourceName.isNotEmpty ? act.sourceName : 'India Code — Ministry of Law & Justice, Govt. of India'),
              _infoRow(tr('Official Source URL'), act.sourceUrl != null && act.sourceUrl!.isNotEmpty ? act.sourceUrl! : 'https://www.indiacode.gov.in/'),
              _infoRow(tr('Number of Sections'), _isLoading ? '...' : '${_sections.length} ${tr("verified sections")}'),
            ]),
            const SizedBox(height: 20),

            // Sections List Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader(tr('Sections'), Icons.format_list_numbered_rounded),
                if (!_isLoading)
                  Text(
                    '${_sections.length} ${tr("provisions")}',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF94A3B8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: CircularProgressIndicator(color: Color(0xFF6366F1)),
                ),
              )
            else if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                ),
                child: Text(
                  _errorMessage!,
                  style: GoogleFonts.inter(color: const Color(0xFFFCA5A5), fontSize: 13),
                ),
              )
            else if (_sections.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.folder_open_rounded, color: Color(0xFF64748B), size: 36),
                    const SizedBox(height: 10),
                    Text(
                      tr('No sections found for this Act in database.'),
                      style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _sections.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final sec = _sections[index];
                  final secColor = _getStatusColor(sec.status);

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AdminSectionDetailScreen(
                              section: sec,
                              actName: act.name,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF334155)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                sec.sectionNumber,
                                style: GoogleFonts.inter(
                                  color: const Color(0xFFA5B4FC),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    sec.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (sec.simpleExplanation.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      sec.simpleExplanation,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFF94A3B8),
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: secColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                sec.status.toUpperCase(),
                                style: GoogleFonts.inter(
                                  color: secColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right_rounded, color: Color(0xFF64748B), size: 18),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
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
            width: 130,
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

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return raw;
    }
  }
}
