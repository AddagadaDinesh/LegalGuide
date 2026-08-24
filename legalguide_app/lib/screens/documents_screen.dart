import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/legal_section.dart';
import '../repositories/legal_data_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/icon_badge.dart';
import 'section_detail_screen.dart';

class _DocGuide {
  final String title;
  final IconData icon;
  final Color color;
  final String whatItIs;
  final String whenUsed;
  final String keyParts;
  final List<String> relatedSectionKeywords;

  const _DocGuide({
    required this.title,
    required this.icon,
    required this.color,
    required this.whatItIs,
    required this.whenUsed,
    required this.keyParts,
    required this.relatedSectionKeywords,
  });
}

/// General procedural explanations, not verbatim statute text.
/// Cross-verified via web search (see project notes) — 2026-08-20.
const _docGuides = [
  _DocGuide(
    title: 'FIR / Police Complaint',
    icon: Icons.local_police_rounded,
    color: Color(0xFFF43F5E),
    whatItIs: 'A First Information Report (FIR) is the written record police prepare on '
        'receiving the first information about a cognizable offence.',
    whenUsed: 'Filed at a police station to start a formal criminal investigation. '
        'Police must register it if the information discloses a cognizable offence '
        '(BNSS Section 173).',
    keyParts: 'Date, time, and place of the incident; description of what happened; '
        'details of the accused/witnesses if known; the informant\'s signature.',
    relatedSectionKeywords: ['theft', 'cheating', 'murder', 'arrest'],
  ),
  _DocGuide(
    title: 'Legal Notice',
    icon: Icons.mail_rounded,
    color: Color(0xFFF59E0B),
    whatItIs: 'A formal written communication warning the recipient of an intended legal '
        'action if a grievance isn\'t resolved.',
    whenUsed: 'Sent before filing a civil suit, as a pre-litigation step — usually optional, '
        'but mandatory in some cases (e.g. suits against the government, under CPC Section 80).',
    keyParts: 'The grievance, the relief/remedy sought, a reasonable deadline to respond, '
        'sender\'s and recipient\'s details.',
    relatedSectionKeywords: [],
  ),
  _DocGuide(
    title: 'Court Summons / Notice',
    icon: Icons.gavel_rounded,
    color: Color(0xFF3B82F6),
    whatItIs: 'A formal court order compelling a person to appear — as a witness, to answer '
        'a civil claim, or to face a criminal charge.',
    whenUsed: 'Civil cases follow CPC Order V; criminal cases follow BNSS Section 63/204 once '
        'a Magistrate takes cognizance of a complaint or police report.',
    keyParts: 'The case reference, date/time/place to appear, and the purpose of the appearance.',
    relatedSectionKeywords: ['arrest'],
  ),
  _DocGuide(
    title: 'Affidavit',
    icon: Icons.fact_check_rounded,
    color: Color(0xFF14B8A6),
    whatItIs: 'A written statement sworn under oath before a notary or magistrate, limited to '
        'facts within the deponent\'s personal knowledge.',
    whenUsed: 'Supporting a court application such as a bail bond, interim injunction, or '
        'maintenance claim. A false statement in one is punishable as perjury.',
    keyParts: 'The deponent\'s sworn statement of facts, signed and notarized on non-judicial '
        'stamp paper.',
    relatedSectionKeywords: [],
  ),
  _DocGuide(
    title: 'Complaint',
    icon: Icons.report_rounded,
    color: Color(0xFFFB923C),
    whatItIs: 'An allegation made to a Magistrate that a person has committed an offence, '
        'with a view to their being prosecuted.',
    whenUsed: 'When a person wants a court (rather than the police directly) to take up a '
        'criminal matter.',
    keyParts: 'The allegation, the accused (if known), and supporting facts.',
    relatedSectionKeywords: ['cheating'],
  ),
  _DocGuide(
    title: 'Property & Sale Deeds',
    icon: Icons.home_work_rounded,
    color: Color(0xFF22D3EE),
    whatItIs: 'Title deeds, sale agreements, encumbrance certificates (EC), and mutation '
        'records establishing ownership of immovable property.',
    whenUsed: 'Before buying, selling, or taking a loan against property — to verify the '
        'seller genuinely owns it and it is free of pending disputes or charges.',
    keyParts: 'Survey number and boundary schedule; stamp duty and registration receipt; '
        'a clear chain of prior title/ownership; an encumbrance search (commonly 30 years).',
    relatedSectionKeywords: [],
  ),
  _DocGuide(
    title: 'Cheque Bounce Notice (Section 138, NI Act)',
    icon: Icons.payments_rounded,
    color: Color(0xFFA78BFA),
    whatItIs: 'A statutory demand notice sent after a cheque is dishonoured due to '
        'insufficient funds, required by the Negotiable Instruments Act.',
    whenUsed: 'Must be sent within 30 days of learning the cheque bounced, giving the '
        'drawer 15 days to pay — a mandatory step before filing a criminal complaint under '
        'Section 138 of the NI Act.',
    keyParts: 'Cheque number and the bank\'s return memo; a clear 15-day demand for '
        'payment; proof the notice was sent by registered post.',
    relatedSectionKeywords: [],
  ),
  _DocGuide(
    title: 'Evidence / Documents',
    icon: Icons.folder_copy_rounded,
    color: AppColors.accent,
    whatItIs: 'Supporting material — physical, documentary, or digital — used to prove facts '
        'in a legal proceeding.',
    whenUsed: 'Gathered during investigation or trial to support a complaint, defence, or claim.',
    keyParts: 'Chain of custody, authenticity, and relevance to the facts in dispute.',
    relatedSectionKeywords: [],
  ),
];

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  late Future<List<LegalSection>> _sectionsFuture;

  @override
  void initState() {
    super.initState();
    _sectionsFuture = LegalDataRepository.loadSections();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('Legal Documents & Notice Guides',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 16)),
      ),
      body: FutureBuilder<List<LegalSection>>(
        future: _sectionsFuture,
        builder: (context, snapshot) {
          final sections = snapshot.data ?? [];

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _docGuides.length,
            itemBuilder: (context, index) {
              final guide = _docGuides[index];
              final related = sections
                  .where((s) => guide.relatedSectionKeywords.any(
                        (kw) => s.title.toLowerCase().contains(kw),
                      ))
                  .toList();

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: guide.color.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconBadge(icon: guide.icon, color: guide.color, size: 38, iconSize: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(guide.title,
                              style: GoogleFonts.outfit(
                                  color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15.5)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('General guide',
                              style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 10)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _label('What it is'),
                    _body(guide.whatItIs),
                    const SizedBox(height: 8),
                    _label('When it\'s used'),
                    _body(guide.whenUsed),
                    const SizedBox(height: 8),
                    _label('Key parts'),
                    _body(guide.keyParts),
                    if (related.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _label('Related legal sections'),
                      for (final section in related)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => SectionDetailScreen(section: section)),
                              );
                            },
                            child: Text(
                              '${section.sectionNumber} — ${section.title}',
                              style: GoogleFonts.inter(
                                  color: guide.color, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
      );

  Widget _body(String text) => Text(
        text,
        style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
      );
}
