import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/category.dart';
import '../models/law.dart';
import '../models/legal_section.dart';
import '../repositories/legal_data_repository.dart';
import '../theme/app_theme.dart';
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
    final style = categoryStyleFor(widget.category.name);
    final body = Container(
      color: AppColors.bg,
      child: FutureBuilder<List<Law>>(
        future: _lawsFuture,
        builder: (context, lawSnapshot) {
          if (lawSnapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: style.color),
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
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: AppColors.border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: ExpansionTile(
                      shape: const Border(),
                      iconColor: style.color,
                      collapsedIconColor: Colors.white70,
                      title: Text(
                        law.name,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15.5,
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
                            color: AppColors.textSecondary,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                      children: [
                        Divider(color: AppColors.border, height: 1),
                        if (lawSections.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'No sections loaded for this law.',
                              style: GoogleFonts.inter(
                                color: AppColors.textMuted,
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
                                      color: style.color,
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
                                    Icons.chevron_right_rounded,
                                    color: AppColors.textMuted,
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
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          widget.category.name,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: body,
    );
  }
}
