import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../localization/app_strings.dart';
import '../models/chat_message.dart';
import '../screens/explore_laws_screen.dart';
import '../services/assistant_service.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';

/// A polished, modern, mobile-first legal AI response widget.
///
/// Features:
/// 1. Prominent "🟣 Quick Answer" card at the very top.
/// 2. Question-specific structured sections with tailored icons (⚡ Key Points,
///    📋 What You Should Do, ⚖️ Relevant Law, etc.).
/// 3. Collapsible "📖 Read More ▼" for long statutory details and background.
/// 4. "🔊 Listen" (TTS) button respecting current app language (English/Telugu/Hindi).
/// 5. Optional "✨ Summarize this answer" button with concise on-demand bullet summary.
/// 6. Proper Markdown & table rendering without raw formatting characters (`**`, `<br>`, `|`).
/// 7. Contextual actions: [🔊 Listen / ⏹ Stop], [📖 Read More], [📋 Copy], [⚖️ View Official Source], [📞 Get Help].
class AiResponseCard extends StatefulWidget {
  final ChatMessage message;

  const AiResponseCard({super.key, required this.message});

  @override
  State<AiResponseCard> createState() => _AiResponseCardState();
}

class _AiResponseCardState extends State<AiResponseCard> {
  bool _isExpanded = false;
  bool _showSummary = false;
  bool _isSummarizing = false;
  List<String>? _summaryBullets;
  late final _AiParsedResponse _parsed;
  late final String _ttsId;

  @override
  void initState() {
    super.initState();
    _parsed = _AiParser.parse(widget.message.text);
    _ttsId = 'ai_msg_${widget.message.timestamp.millisecondsSinceEpoch}';
  }

  @override
  void didUpdateWidget(covariant AiResponseCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.text != widget.message.text) {
      if (TtsService.instance.currentlyPlayingId.value == _ttsId) {
        TtsService.instance.stop();
      }
      _parsed = _AiParser.parse(widget.message.text);
      _summaryBullets = null;
      _showSummary = false;
    }
  }

  @override
  void dispose() {
    if (TtsService.instance.currentlyPlayingId.value == _ttsId) {
      TtsService.instance.stop();
    }
    super.dispose();
  }

  Future<void> _handleSummarize() async {
    if (_showSummary) {
      setState(() => _showSummary = false);
      return;
    }

    if (_summaryBullets != null && _summaryBullets!.isNotEmpty) {
      setState(() => _showSummary = true);
      return;
    }

    setState(() => _isSummarizing = true);

    try {
      final bullets = await AssistantService.summarize(_parsed.cleanTextForCopy);
      if (mounted) {
        setState(() {
          _summaryBullets = bullets;
          _showSummary = true;
          _isSummarizing = false;
        });
      }
    } catch (_) {
      if (mounted) {
        final fallback = AssistantService.extractLocalSummary(_parsed.cleanTextForCopy);
        setState(() {
          _summaryBullets = fallback;
          _showSummary = true;
          _isSummarizing = false;
        });
      }
    }
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _parsed.cleanTextForCopy));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr('Copied to clipboard')),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openLawQuery(String query) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExploreLawsScreen(initialQuery: query, showAppBar: true),
      ),
    );
  }

  Future<void> _callHelpline(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasDetailedContent = _parsed.detailedSections.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status indicator (Offline / Online / Login hint)
          if (widget.message.requiresLogin)
            _buildStatusBanner(
              icon: Icons.lock_outline_rounded,
              color: const Color(0xFF64748B),
              text: tr('🔒 Log in or create an account for answers beyond app content'),
            )
          else if (widget.message.isOnline == false)
            _buildStatusBanner(
              icon: Icons.offline_bolt_rounded,
              color: const Color(0xFFF59E0B),
              text: tr('🟠 Offline – Using LegalGuide Knowledge'),
            )
          else if (widget.message.isOnline == true)
            _buildStatusBanner(
              icon: Icons.cloud_done_rounded,
              color: const Color(0xFF10B981),
              text: tr('🟢 Online'),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Quick Answer Card (Always visible at the top)
                if (_parsed.quickAnswer.isNotEmpty) ...[
                  _buildQuickAnswerCard(_parsed.quickAnswer),
                  const SizedBox(height: 14),
                ],

                // 2. Primary Sections (Key Points, What You Should Do, etc.)
                for (final section in _parsed.primarySections) ...[
                  _buildSectionWidget(section),
                  const SizedBox(height: 14),
                ],

                // 3. Collapsible Long / Detailed Content
                if (hasDetailedContent) ...[
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final section in _parsed.detailedSections) ...[
                          _buildSectionWidget(section),
                          const SizedBox(height: 14),
                        ],
                      ],
                    ),
                    crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 220),
                  ),
                ],

                // 4. Action Toolbar
                _buildActionToolbar(hasDetailedContent),

                // 5. Optional Summarize this answer section
                const SizedBox(height: 12),
                if (_showSummary && _summaryBullets != null && _summaryBullets!.isNotEmpty)
                  _buildQuickSummaryCard()
                else
                  _buildSummarizeButton(),

                // 6. Non-intrusive legal disclaimer
                const SizedBox(height: 12),
                _buildDisclaimer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner({required IconData icon, required Color color, required String text}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(bottom: BorderSide(color: color.withValues(alpha: 0.25))),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(color: color, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAnswerCard(String quickAnswer) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1E1B4B), // Rich Deep Indigo (Solid 100% opaque)
            Color(0xFF312E81), // Deep Royal Indigo (Solid 100% opaque)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6366F1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E1B4B).withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4338CA),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFA5B4FC), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt_rounded, size: 14, color: Color(0xFFFCD34D)),
                    const SizedBox(width: 4),
                    Text(
                      tr('QUICK ANSWER'),
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildRichText(
            quickAnswer,
            baseStyle: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
            boldStyle: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionWidget(_AiSection section) {
    // If it's a dedicated Relevant Law section, give it a distinctive legal badge card
    if (section.isRelevantLaw) {
      return _buildRelevantLawCard(section);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header with Icon
        if (section.title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(section.icon, size: 17, color: section.color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    section.title,
                    style: GoogleFonts.inter(
                      color: section.color,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Section Content Items
        for (final item in section.items) ...[
          if (item is _BulletItem)
            _buildBulletRow(item.text)
          else if (item is _NumberedItem)
            _buildNumberedRow(item.number, item.text)
          else if (item is _TableItem)
            _buildTableCard(item)
          else if (item is _ParagraphItem)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _buildRichText(
                item.text,
                baseStyle: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 13.5,
                  height: 1.45,
                ),
                boldStyle: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  height: 1.45,
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildRelevantLawCard(_AiSection section) {
    final text = section.items.map((i) => i.rawText).join('\n');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B4B), // Solid opaque deep indigo
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF6366F1), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E1B4B).withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.gavel_rounded, size: 16, color: Color(0xFFA5B4FC)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  section.title.isNotEmpty ? section.title : tr('Relevant Law'),
                  style: GoogleFonts.inter(
                    color: const Color(0xFFA5B4FC),
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_parsed.detectedLawQuery != null)
                InkWell(
                  onTap: () => _openLawQuery(_parsed.detectedLawQuery!),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4338CA),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFA5B4FC)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          tr('View Official Source'),
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_rounded, size: 11, color: Colors.white),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _buildRichText(
            text,
            baseStyle: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 13.5,
              height: 1.45,
            ),
            boldStyle: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletRow(String text, {Color? bulletColor, Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6, right: 10),
            width: 5.5,
            height: 5.5,
            decoration: BoxDecoration(
              color: bulletColor ?? AppColors.accent,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: _buildRichText(
              text,
              baseStyle: GoogleFonts.inter(
                color: textColor ?? AppColors.textPrimary,
                fontSize: 13.5,
                height: 1.4,
              ),
              boldStyle: GoogleFonts.inter(
                color: textColor ?? AppColors.textPrimary,
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberedRow(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2, right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
            ),
            child: Text(
              number,
              style: GoogleFonts.inter(
                color: AppColors.accent,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: _buildRichText(
              text,
              baseStyle: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 13.5,
                height: 1.4,
              ),
              boldStyle: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableCard(_TableItem item) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 38,
            dataRowMinHeight: 36,
            dataRowMaxHeight: 50,
            horizontalMargin: 12,
            columnSpacing: 16,
            headingRowColor: WidgetStateProperty.all(AppColors.surface),
            columns: [
              for (final header in item.headers)
                DataColumn(
                  label: Text(
                    _AiParser.stripAllFormatting(header),
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
            rows: [
              for (final row in item.rows)
                DataRow(
                  cells: [
                    for (final cell in row)
                      DataCell(
                        Text(
                          _AiParser.stripAllFormatting(cell),
                          style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionToolbar(bool hasDetailedContent) {
    return ValueListenableBuilder<String?>(
      valueListenable: TtsService.instance.currentlyPlayingId,
      builder: (context, playingId, _) {
        final isPlaying = playingId == _ttsId;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(color: AppColors.border, height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // 1. Listen / Stop Button
                InkWell(
                  onTap: () {
                    if (isPlaying) {
                      TtsService.instance.stop();
                    } else {
                      final completeText = _parsed.buildCompleteTtsText(
                        summaryBullets: _showSummary ? _summaryBullets : null,
                      );
                      TtsService.instance.speak(completeText, id: _ttsId);
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6.5),
                    decoration: BoxDecoration(
                      color: isPlaying
                          ? const Color(0xFFFEE2E2)
                          : const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isPlaying ? const Color(0xFFFCA5A5) : const Color(0xFFC7D2FE),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPlaying ? Icons.stop_rounded : Icons.volume_up_rounded,
                          size: 16,
                          color: isPlaying ? const Color(0xFFDC2626) : const Color(0xFF4338CA),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isPlaying ? tr('Stop') : tr('Listen'),
                          style: GoogleFonts.inter(
                            color: isPlaying ? const Color(0xFFDC2626) : const Color(0xFF4338CA),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. Read More / Read Less Toggle
                if (hasDetailedContent)
                  InkWell(
                    onTap: () => setState(() => _isExpanded = !_isExpanded),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isExpanded ? Icons.expand_less_rounded : Icons.menu_book_rounded,
                            size: 14,
                            color: const Color(0xFF1E293B),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _isExpanded ? tr('Read Less') : tr('Read More'),
                            style: GoogleFonts.inter(
                              color: const Color(0xFF1E293B),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            _isExpanded ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
                            size: 16,
                            color: const Color(0xFF1E293B),
                          ),
                        ],
                      ),
                    ),
                  ),

                // 3. Copy Button
                InkWell(
                  onTap: _copyToClipboard,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.copy_rounded, size: 13, color: Color(0xFF1E293B)),
                        const SizedBox(width: 5),
                        Text(
                          tr('Copy'),
                          style: GoogleFonts.inter(
                            color: const Color(0xFF1E293B),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 4. View Law Button (if detected and not already in relevant law card)
                if (_parsed.detectedLawQuery != null)
                  InkWell(
                    onTap: () => _openLawQuery(_parsed.detectedLawQuery!),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF312E81).withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.balance_rounded, size: 13, color: Color(0xFFA5B4FC)),
                          const SizedBox(width: 5),
                          Text(
                            tr('View Official Source'),
                            style: GoogleFonts.inter(
                              color: const Color(0xFFA5B4FC),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // 5. Emergency Helpline Button (if detected)
                if (_parsed.detectedHelpline != null)
                  InkWell(
                    onTap: () => _callHelpline(_parsed.detectedHelpline!),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.phone_in_talk_rounded, size: 13, color: Color(0xFFEF4444)),
                          const SizedBox(width: 5),
                          Text(
                            '${tr("Get Help")} (${_parsed.detectedHelpline})',
                            style: GoogleFonts.inter(
                              color: const Color(0xFFEF4444),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummarizeButton() {
    return InkWell(
      onTap: _isSummarizing ? null : _handleSummarize,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF818CF8), width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isSummarizing) ...[
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4338CA)),
              ),
              const SizedBox(width: 8),
              Text(
                tr('Summarizing...'),
                style: GoogleFonts.inter(
                  color: const Color(0xFF4338CA),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ] else ...[
              const Icon(Icons.auto_awesome, size: 16, color: Color(0xFF4338CA)),
              const SizedBox(width: 8),
              Text(
                tr('Summarize this answer'),
                style: GoogleFonts.inter(
                  color: const Color(0xFF4338CA),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSummaryCard() {
    final bullets = _summaryBullets ?? [];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2E1065), // Solid Deep Purple
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF8B5CF6), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E1065).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, size: 16, color: Color(0xFFFCD34D)),
                  const SizedBox(width: 7),
                  Text(
                    tr('Quick Summary'),
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => setState(() => _showSummary = false),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        tr('Hide Summary'),
                        style: GoogleFonts.inter(
                          color: const Color(0xFFDDD6FE),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.arrow_drop_up_rounded, size: 16, color: Color(0xFFDDD6FE)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final bullet in bullets)
            _buildBulletRow(bullet, bulletColor: const Color(0xFFC084FC), textColor: Colors.white),
        ],
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          tr('LegalGuide provides general legal information and does not replace advice from a qualified advocate.'),
          style: GoogleFonts.inter(
            color: AppColors.textSecondary.withValues(alpha: 0.55),
            fontSize: 10,
            fontStyle: FontStyle.italic,
            height: 1.35,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// Parses in-line bold (**text** or <b>text</b>), stripping all HTML/Markdown tags.
  Widget _buildRichText(
    String text, {
    required TextStyle baseStyle,
    required TextStyle boldStyle,
  }) {
    final cleaned = _AiParser.cleanInlineText(text);
    final spans = <TextSpan>[];

    // Split on ** or __
    final regex = RegExp(r'\*\*(.*?)\*\*');
    int lastMatchEnd = 0;

    for (final match in regex.allMatches(cleaned)) {
      if (match.start > lastMatchEnd) {
        final plainPart = cleaned.substring(lastMatchEnd, match.start).replaceAll('**', '');
        if (plainPart.isNotEmpty) {
          spans.add(TextSpan(
            text: plainPart,
            style: baseStyle,
          ));
        }
      }
      final boldContent = (match.group(1) ?? '').replaceAll('**', '');
      if (boldContent.isNotEmpty) {
        spans.add(TextSpan(
          text: boldContent,
          style: boldStyle,
        ));
      }
      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < cleaned.length) {
      final tail = cleaned.substring(lastMatchEnd).replaceAll('**', '');
      if (tail.isNotEmpty) {
        spans.add(TextSpan(
          text: tail,
          style: baseStyle,
        ));
      }
    }

    return Text.rich(
      TextSpan(children: spans),
      style: baseStyle,
    );
  }
}

// ---------------------------------------------------------------------------
// PARSER & DATA STRUCTURES
// ---------------------------------------------------------------------------

class _AiParsedResponse {
  final String quickAnswer;
  final List<_AiSection> primarySections;
  final List<_AiSection> detailedSections;
  final String? detectedLawQuery;
  final String? detectedHelpline;
  final String cleanTextForCopy;

  _AiParsedResponse({
    required this.quickAnswer,
    required this.primarySections,
    required this.detailedSections,
    this.detectedLawQuery,
    this.detectedHelpline,
    required this.cleanTextForCopy,
  });

  /// Constructs the complete visible response text for Text-to-Speech in structured order:
  /// Quick Answer -> Key Points -> What You Should Do -> Applicable Laws -> Documents ->
  /// Examples -> Important -> Quick Summary (if visible).
  String buildCompleteTtsText({List<String>? summaryBullets}) {
    final buffer = StringBuffer();

    // 1. Quick Answer
    if (quickAnswer.isNotEmpty) {
      final cleanQa = _AiParser.cleanForSpeech(quickAnswer);
      if (cleanQa.isNotEmpty) {
        buffer.writeln('${tr("Quick Answer")}:');
        buffer.writeln(cleanQa);
        buffer.writeln();
      }
    }

    // 2. Primary Sections
    for (final sec in primarySections) {
      final secTitle = _AiParser.cleanForSpeech(sec.title);
      if (secTitle.isNotEmpty) {
        buffer.writeln('$secTitle:');
      }
      for (final item in sec.items) {
        final itemSpeech = _AiParser.cleanForSpeech(item.rawText);
        if (itemSpeech.isNotEmpty) {
          buffer.writeln(itemSpeech);
        }
      }
      buffer.writeln();
    }

    // 3. Detailed Sections (Applicable Laws, Background, Penalties, etc.)
    for (final sec in detailedSections) {
      final secTitle = _AiParser.cleanForSpeech(sec.title);
      if (secTitle.isNotEmpty) {
        buffer.writeln('$secTitle:');
      }
      for (final item in sec.items) {
        final itemSpeech = _AiParser.cleanForSpeech(item.rawText);
        if (itemSpeech.isNotEmpty) {
          buffer.writeln(itemSpeech);
        }
      }
      buffer.writeln();
    }

    // 4. Quick Summary (if generated and visible)
    if (summaryBullets != null && summaryBullets.isNotEmpty) {
      buffer.writeln('${tr("Quick Summary")}:');
      for (final bullet in summaryBullets) {
        final bSpeech = _AiParser.cleanForSpeech(bullet);
        if (bSpeech.isNotEmpty) {
          buffer.writeln(bSpeech);
        }
      }
      buffer.writeln();
    }

    final full = buffer.toString().trim();
    if (full.isNotEmpty) return full;
    return _AiParser.cleanForSpeech(cleanTextForCopy);
  }
}

class _AiSection {
  final String title;
  final IconData icon;
  final Color color;
  final List<_AiContentItem> items;
  final bool isDetailed;
  final bool isRelevantLaw;

  _AiSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
    this.isDetailed = false,
    this.isRelevantLaw = false,
  });
}

abstract class _AiContentItem {
  String get rawText;
}

class _ParagraphItem extends _AiContentItem {
  final String text;
  _ParagraphItem(this.text);
  @override
  String get rawText => text;
}

class _BulletItem extends _AiContentItem {
  final String text;
  _BulletItem(this.text);
  @override
  String get rawText => text;
}

class _NumberedItem extends _AiContentItem {
  final String number;
  final String text;
  _NumberedItem(this.number, this.text);
  @override
  String get rawText => '$number $text';
}

class _TableItem extends _AiContentItem {
  final List<String> headers;
  final List<List<String>> rows;
  _TableItem(this.headers, this.rows);
  @override
  String get rawText => '${headers.join(' | ')}\n${rows.map((r) => r.join(' | ')).join('\n')}';
}

class _AiParser {
  /// Cleans raw HTML tags, entity references, and stray symbols.
  static String cleanInlineText(String text) {
    var s = text;
    s = s.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    s = s.replaceAll(RegExp(r'</?(?:p|div|span|strong|b|em|i|u|h[1-6]|table|tr|td|th|tbody|thead)[^>]*>', caseSensitive: false), '');
    s = s.replaceAll('&nbsp;', ' ');
    s = s.replaceAll('&amp;', '&');
    s = s.replaceAll('&quot;', '"');
    s = s.replaceAll('&#39;', "'");
    s = s.replaceAll('&lt;', '<');
    s = s.replaceAll('&gt;', '>');
    return s;
  }

  static String stripAllFormatting(String text) {
    var s = cleanInlineText(text);
    s = s.replaceAll(RegExp(r'#{1,6}\s*'), '');
    s = s.replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'$1');
    s = s.replaceAll(RegExp(r'\*(.*?)\*'), r'$1');
    s = s.replaceAll(RegExp(r'^\s*[-*•]\s+', multiLine: true), '');
    s = s.replaceAll(RegExp(r'^\s*\d+\.\s+', multiLine: true), '');
    return s.trim();
  }

  /// Cleans markdown/HTML tokens, emojis, and artifacts specifically for natural TTS voice playback.
  static String cleanForSpeech(String text) {
    if (text.isEmpty) return '';
    var s = cleanInlineText(text);
    // Remove markdown links [Title](url) -> Title
    s = s.replaceAllMapped(RegExp(r'\[(.*?)\]\(.*?\)'), (m) => m.group(1) ?? '');
    // Remove markdown headers #, ##, ###
    s = s.replaceAll(RegExp(r'#{1,6}\s*'), '');
    // Remove bold/italics markers
    s = s.replaceAll('**', '').replaceAll('*', '').replaceAll('__', '').replaceAll('_', '');
    // Remove emojis that cause garbled TTS output
    s = s.replaceAll(RegExp(r'[\u{1F300}-\u{1F6FF}\u{1F900}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]', unicode: true), '');
    // Clean bullet points and list indicators
    s = s.replaceAll(RegExp(r'^\s*[-*•]\s*', multiLine: true), '');
    // Remove table pipes
    s = s.replaceAll('|', ' ');
    // Normalize punctuation & whitespace
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }

  static _AiParsedResponse parse(String rawText) {
    final cleaned = cleanInlineText(rawText);
    final lines = cleaned.split('\n');

    String quickAnswer = '';
    final List<_AiSection> allSections = [];
    String? currentHeading;
    List<_AiContentItem> currentItems = [];
    List<String> currentTableLines = [];

    void flushTable() {
      if (currentTableLines.isEmpty) return;
      final parsed = _parseTable(currentTableLines);
      if (parsed != null) currentItems.add(parsed);
      currentTableLines = [];
    }

    void flushSection() {
      flushTable();
      if (currentHeading == null && currentItems.isEmpty) return;

      final heading = currentHeading ?? '';
      final isQa = _isQuickAnswerHeading(heading);

      if (isQa) {
        // Collect paragraphs from quick answer
        quickAnswer = currentItems.map((e) => e.rawText).join('\n\n').trim();
      } else if (currentItems.isNotEmpty) {
        final meta = _determineSectionMeta(heading);
        allSections.add(_AiSection(
          title: heading,
          icon: meta.icon,
          color: meta.color,
          items: List.from(currentItems),
          isDetailed: meta.isDetailed,
          isRelevantLaw: meta.isRelevantLaw,
        ));
      }
      currentHeading = null;
      currentItems = [];
    }

    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        flushTable();
        continue;
      }

      // Check if this line is a markdown table line (| ... |)
      if (trimmed.startsWith('|') && trimmed.endsWith('|') && trimmed.length > 2) {
        currentTableLines.add(trimmed);
        continue;
      } else {
        flushTable();
      }

      // Check if this is a heading (### Heading or **Heading:**)
      final headingMatch = _matchHeading(trimmed);
      if (headingMatch != null) {
        flushSection();
        currentHeading = headingMatch;
        continue;
      }

      // Check if bullet point (- item, * item, • item)
      final bulletMatch = RegExp(r'^[-*•]\s+(.*)$').firstMatch(trimmed);
      if (bulletMatch != null) {
        currentItems.add(_BulletItem(bulletMatch.group(1) ?? ''));
        continue;
      }

      // Check if numbered list (1. item, (1) item)
      final numMatch = RegExp(r'^(?:(\d+)\.|\((\d+)\))\s+(.*)$').firstMatch(trimmed);
      if (numMatch != null) {
        final num = numMatch.group(1) ?? numMatch.group(2) ?? '1';
        currentItems.add(_NumberedItem(num, numMatch.group(3) ?? ''));
        continue;
      }

      // Normal paragraph
      currentItems.add(_ParagraphItem(trimmed));
    }
    flushSection();

    // If Quick Answer was not explicitly tagged with a heading, extract the first paragraph
    if (quickAnswer.isEmpty && allSections.isNotEmpty) {
      final firstSec = allSections.first;
      // If the first section has no title or is just a general paragraph, use it as quick answer
      if (firstSec.title.isEmpty && firstSec.items.isNotEmpty) {
        quickAnswer = firstSec.items.map((i) => i.rawText).join('\n\n').trim();
        allSections.removeAt(0);
      } else if (firstSec.items.isNotEmpty && firstSec.items.first is _ParagraphItem) {
        // If first item is a direct paragraph
        quickAnswer = firstSec.items.first.rawText;
        firstSec.items.removeAt(0);
        if (firstSec.items.isEmpty) allSections.removeAt(0);
      }
    }

    // Split sections into primary vs detailed (collapsible)
    final primary = <_AiSection>[];
    final detailed = <_AiSection>[];

    for (final sec in allSections) {
      if (sec.isDetailed) {
        detailed.add(sec);
      } else {
        primary.add(sec);
      }
    }

    // If there are many sections (> 3) and none explicitly marked detailed, make the rest collapsible
    if (detailed.isEmpty && primary.length > 3) {
      final moveCount = primary.length - 2;
      for (int i = 0; i < moveCount; i++) {
        detailed.add(primary.removeAt(2));
      }
    }

    // Detect legal provision query
    final detectedLaw = _detectLawQuery(rawText);

    // Detect emergency helpline
    final detectedHelpline = _detectHelpline(rawText);

    final cleanText = stripAllFormatting(rawText);

    return _AiParsedResponse(
      quickAnswer: quickAnswer,
      primarySections: primary,
      detailedSections: detailed,
      detectedLawQuery: detectedLaw,
      detectedHelpline: detectedHelpline,
      cleanTextForCopy: cleanText,
    );
  }

  static String? _matchHeading(String line) {
    // Matches ### Heading or ## Heading or # Heading
    final hashMatch = RegExp(r'^#{1,6}\s*(.*)$').firstMatch(line);
    if (hashMatch != null) {
      return hashMatch.group(1)?.replaceAll(RegExp(r'[:#*]'), '').trim();
    }

    // Matches **Heading Title:** or **Heading Title** on a single line
    final boldMatch = RegExp(r'^\*\*(.*?)\*\*:?$').firstMatch(line);
    if (boldMatch != null && (boldMatch.group(1)?.length ?? 0) < 55) {
      return boldMatch.group(1)?.replaceAll(RegExp(r'[:#*]'), '').trim();
    }

    // Matches emoji-prefixed section lines (e.g. ⚖️ Answer, 📋 What You Should Do, 🔑 Key Points)
    if (line.startsWith('⚖️') ||
        line.startsWith('📋') ||
        line.startsWith('🔑') ||
        line.startsWith('⚡') ||
        line.startsWith('📄') ||
        line.startsWith('💡') ||
        line.startsWith('📞') ||
        line.startsWith('🟣')) {
      if (line.length < 50 && !line.contains('\n')) {
        return line.replaceAll(RegExp(r'[:#*]'), '').trim();
      }
    }

    return null;
  }

  static bool _isQuickAnswerHeading(String heading) {
    final lower = heading.toLowerCase();
    if (lower.contains('relevant law') || lower.contains('more details')) return false;
    return lower.contains('quick answer') ||
        lower == 'answer' ||
        lower == '⚖️ answer' ||
        lower == '🟣 answer' ||
        lower.contains('త్వరిత సమాధానం') ||
        lower.contains('సమాధానం') ||
        lower.contains('त्वरित उत्तर') ||
        lower.contains('उत्तर') ||
        lower.contains('direct answer') ||
        lower.contains('summary answer');
  }

  static _SectionMeta _determineSectionMeta(String heading) {
    final lower = heading.toLowerCase();

    if (lower == 'answer' || lower.contains('⚖️ answer')) {
      return _SectionMeta(Icons.balance_rounded, const Color(0xFF4338CA));
    }

    if (lower.contains('what i understand') ||
        lower.contains('understand') ||
        lower.contains('నేను అర్థం చేసుకున్నది') ||
        lower.contains('मेरी समझ')) {
      return _SectionMeta(Icons.psychology_rounded, const Color(0xFF0369A1));
    }

    if (lower.contains('more details') ||
        lower.contains('detailed') ||
        lower.contains('in-depth') ||
        lower.contains('background') ||
        lower.contains('మరిన్ని వివరాలు') ||
        lower.contains('अधिक विवरण')) {
      return _SectionMeta(Icons.menu_book_rounded, const Color(0xFF4338CA), isDetailed: true);
    }

    if (lower.contains('relevant law') ||
        lower.contains('applicable law') ||
        lower.contains('legal provision') ||
        lower.contains('statute') ||
        lower.contains('bns') ||
        lower.contains('bnss') ||
        lower.contains('bsa') ||
        lower.contains('సంబంధిత చట్టం') ||
        lower.contains('వర్తించే చట్టం') ||
        lower.contains('प्रासंगिक कानून') ||
        lower.contains('लागू कानून')) {
      return _SectionMeta(Icons.balance_rounded, const Color(0xFF4338CA), isRelevantLaw: true);
    }

    if (lower.contains('what you should do') ||
        lower.contains('what you can do') ||
        lower.contains('action') ||
        lower.contains('steps') ||
        lower.contains('procedure') ||
        lower.contains('మీరు ఏమి చేయాలి') ||
        lower.contains('మీరు ఏమి చేయవచ్చు') ||
        lower.contains('क्या करना चाहिए') ||
        lower.contains('आप क्या कर सकते हैं')) {
      return _SectionMeta(Icons.task_alt_rounded, const Color(0xFF047857));
    }

    if (lower.contains('your rights') ||
        lower.contains('citizen rights') ||
        lower.contains('protection') ||
        lower.contains('హక్కులు') ||
        lower.contains('अधिकार')) {
      return _SectionMeta(Icons.shield_rounded, const Color(0xFF0284C7));
    }

    if (lower.contains('key point') ||
        lower.contains('meaning') ||
        lower.contains('elements') ||
        lower.contains('🔑') ||
        lower.contains('⚡') ||
        lower.contains('ముఖ్య అంశాలు') ||
        lower.contains('मुख्य बिंदु')) {
      return _SectionMeta(Icons.flash_on_rounded, const Color(0xFFB45309));
    }

    if (lower.contains('punishment') ||
        lower.contains('penalty') ||
        lower.contains('fine') ||
        lower.contains('jail') ||
        lower.contains('శిక్ష') ||
        lower.contains('सज़ा')) {
      return _SectionMeta(Icons.warning_amber_rounded, const Color(0xFFDC2626));
    }

    if (lower.contains('document') ||
        lower.contains('evidence') ||
        lower.contains('record') ||
        lower.contains('పత్రాలు') ||
        lower.contains('ఆధారాలు') ||
        lower.contains('दस्तावेज़') ||
        lower.contains('साक्ष्य')) {
      return _SectionMeta(Icons.description_rounded, const Color(0xFF6D28D9));
    }

    if (lower.contains('clarification') ||
        lower.contains('స్పష్టీకరణ') ||
        lower.contains('स्पष्टीकरण')) {
      return _SectionMeta(Icons.help_outline_rounded, const Color(0xFFBE185D));
    }

    if (lower.contains('example') ||
        lower.contains('scenario') ||
        lower.contains('ఉదాహరణ') ||
        lower.contains('उदाहरण')) {
      return _SectionMeta(Icons.lightbulb_rounded, const Color(0xFF0F766E));
    }

    if (lower.contains('help') ||
        lower.contains('helpline') ||
        lower.contains('contact') ||
        lower.contains('సహాయం') ||
        lower.contains('మదద')) {
      return _SectionMeta(Icons.phone_in_talk_rounded, const Color(0xFFDC2626));
    }

    if (lower.contains('caution') ||
        lower.contains('warning') ||
        lower.contains('important') ||
        lower.contains('ముఖ్యమైన') ||
        lower.contains('గమనిక') ||
        lower.contains('महत्वपूर्ण') ||
        lower.contains('सावधानी')) {
      return _SectionMeta(Icons.error_outline_rounded, const Color(0xFFB45309));
    }

    return _SectionMeta(Icons.label_important_rounded, AppColors.accentDark);
  }

  static _TableItem? _parseTable(List<String> rawLines) {
    if (rawLines.isEmpty) return null;
    final clean = rawLines.where((l) => !RegExp(r'^[\|\s\-:]+$').hasMatch(l)).toList();
    if (clean.isEmpty) return null;

    final headers = clean.first
        .split('|')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final rows = <List<String>>[];
    for (int i = 1; i < clean.length; i++) {
      final cells = clean[i]
          .split('|')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (cells.isNotEmpty) rows.add(cells);
    }

    if (headers.isEmpty) return null;
    return _TableItem(headers, rows);
  }

  static String? _detectLawQuery(String text) {
    // Match BNS 303, Section 303 BNS, BNSS 35, MV Act 129, etc.
    final match = RegExp(
      r'(?:(BNS|BNSS|BSA|IPC|CrPC)\s*(?:Act)?\s*(?:Section|Sec\.?)?\s*(\d+[a-zA-Z]*)|(?:Section|Sec\.?)\s*(\d+[a-zA-Z]*)\s*(?:of\s+the\s+)?(BNS|BNSS|BSA|IPC|CrPC|Motor Vehicles Act|Railways Act))',
      caseSensitive: false,
    ).firstMatch(text);

    if (match != null) {
      final code = match.group(1) ?? match.group(4) ?? '';
      final sec = match.group(2) ?? match.group(3) ?? '';
      return '$code $sec'.trim();
    }
    return null;
  }

  static String? _detectHelpline(String text) {
    if (text.contains('112')) return '112';
    if (text.contains('1091')) return '1091';
    if (text.contains('139')) return '139';
    if (text.contains('1930')) return '1930';
    return null;
  }
}

class _SectionMeta {
  final IconData icon;
  final Color color;
  final bool isDetailed;
  final bool isRelevantLaw;

  _SectionMeta(this.icon, this.color, {this.isDetailed = false, this.isRelevantLaw = false});
}
