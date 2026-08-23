import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/category.dart';
import '../models/law.dart';
import '../models/legal_section.dart';
import '../repositories/legal_data_repository.dart';
import 'section_detail_screen.dart';

class LawListScreen extends StatefulWidget {
  final Category category;
  final bool embedded;

  const LawListScreen({super.key, required this.category, this.embedded = false});

  @override
  State<LawListScreen> createState() => _LawListScreenState();
}

class _LawListScreenState extends State<LawListScreen> {
  late Future<List<Law>> _lawsFuture;
  late Future<List<LegalSection>> _sectionsFuture;

  @override
  void initState() {
    super.initState();
    _lawsFuture = LegalDataRepository.loadLaws(categoryId: widget.category.id);
    _sectionsFuture = LegalDataRepository.loadSections();
  }

  @override
  Widget build(BuildContext context) {
    final body = Container(
      color: const Color(0xFF0F172A),
      child: FutureBuilder<List<Law>>(
        future: _lawsFuture,
        builder: (context, lawSnapshot) {
          if (lawSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF6366F1)),
            );
          }

          final laws = lawSnapshot.data ?? [];

          if (laws.isEmpty) {
            return Center(
              child: Text(
                'No laws found for ${widget.category.name}',
                style: GoogleFonts.inter(color: Colors.white70),
              ),
            );
          }

          return FutureBuilder<List<LegalSection>>(
            future: _sectionsFuture,
            builder: (context, sectionSnapshot) {
              final allSections = sectionSnapshot.data ?? [];

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: laws.length,
                itemBuilder: (context, index) {
                  final law = laws[index];
                  final lawSections = allSections
                      .where((s) => s.lawId == law.id)
                      .toList();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: ExpansionTile(
                      shape: const Border(),
                      iconColor: const Color(0xFF6366F1),
                      collapsedIconColor: Colors.white70,
                      title: Text(
                        law.name,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          law.shortName.isNotEmpty
                              ? '${law.shortName} • ${law.description}'
                              : law.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF94A3B8),
                            fontSize: 13,
                          ),
                        ),
                      ),
                      children: [
                        const Divider(color: Color(0xFF334155), height: 1),
                        if (lawSections.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'No sections loaded for this law.',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF64748B),
                                fontSize: 13,
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: lawSections.length,
                            itemBuilder: (context, secIndex) {
                              final sec = lawSections[secIndex];
                              return Material(
                                color: Colors.transparent,
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  title: Text(
                                    '${sec.sectionNumber} - ${sec.title}',
                                    style: GoogleFonts.inter(
                                      color: Colors.cyanAccent,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  subtitle: Text(
                                    sec.simpleExplanation,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFFCBD5E1),
                                      fontSize: 12,
                                    ),
                                  ),
                                  trailing: const Icon(
                                    Icons.chevron_right,
                                    color: Color(0xFF64748B),
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            SectionDetailScreen(section: sec),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Text(
          widget.category.name,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: body,
    );
  }
}
