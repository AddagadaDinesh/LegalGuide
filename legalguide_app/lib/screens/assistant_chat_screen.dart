import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../localization/app_strings.dart';
import '../models/chat_message.dart';
import '../models/conversation.dart';
import '../services/analytics_service.dart';
import '../services/assistant_service.dart';
import '../services/auth_service.dart';
import '../services/chat_history_service.dart';
import '../services/locale_service.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ai_response_card.dart';
import '../widgets/voice_search_modal.dart';
import 'login_screen.dart';

Future<void> showAssistantPanel(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => AnimatedPadding(
      duration: const Duration(milliseconds: 100),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: const FractionallySizedBox(
        heightFactor: 0.9,
        child: AssistantPanel(),
      ),
    ),
  );
}

class AssistantPanel extends StatefulWidget {
  const AssistantPanel({super.key});

  @override
  State<AssistantPanel> createState() => _AssistantPanelState();
}

const _quickQuestions = {
  'Know My Rights': 'What are my basic legal rights as a citizen?',
  'Arrest & Detention': 'What are my rights if I am arrested or detained?',
  'Criminal Law': 'What is theft and cheating under the Bharatiya Nyaya Sanhita?',
  'Constitutional Rights': 'What does Article 21 of the Constitution protect?',
  'Explain a Legal Section': 'Can you explain what a specific legal section means?',
  'Legal Documents': 'What is an FIR and when is a legal notice used?',
};

class _AssistantPanelState extends State<AssistantPanel> {
  Conversation? _currentConversation;
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  bool _isLoadingHistory = true;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    try {
      final conv = await ChatHistoryService.instance.getOrCreateActiveConversation();
      final msgs = await ChatHistoryService.instance.loadMessages(conv.id);
      if (mounted) {
        setState(() {
          _currentConversation = conv;
          _messages.clear();
          _messages.addAll(msgs);
          _isLoadingHistory = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Error loading chat history: $e');
      if (mounted) {
        setState(() => _isLoadingHistory = false);
      }
    }
  }

  Future<void> _startNewChat() async {
    await TtsService.instance.stop();
    try {
      final newConv = await ChatHistoryService.instance.startNewConversation();
      if (mounted) {
        setState(() {
          _currentConversation = newConv;
          _messages.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('Started a new conversation')),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error starting new chat: $e');
    }
  }

  Future<void> _showHistorySheet() async {
    final recent = await ChatHistoryService.instance.getRecentConversations(limit: 40);
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.70,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 16, 14),
                  decoration: const BoxDecoration(
                    color: Color(0xFF4338CA),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.history_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          tr('Recent Conversations'),
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: recent.isEmpty
                      ? Center(
                          child: Text(
                            tr('No previous conversations yet'),
                            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: recent.length,
                          separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.border),
                          itemBuilder: (ctx, index) {
                            final conv = recent[index];
                            final isCurrent = conv.id == _currentConversation?.id;

                            return ListTile(
                              leading: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? const Color(0xFFEEF2FF)
                                      : AppColors.bg,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isCurrent
                                        ? const Color(0xFF818CF8)
                                        : AppColors.border,
                                  ),
                                ),
                                child: Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 18,
                                  color: isCurrent ? AppColors.accentDark : AppColors.textSecondary,
                                ),
                              ),
                              title: Text(
                                conv.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: isCurrent ? AppColors.accentDark : AppColors.textPrimary,
                                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                conv.updatedAt.toString().substring(0, 16),
                                style: GoogleFonts.inter(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isCurrent)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                      margin: const EdgeInsets.only(right: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEEF2FF),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0xFFA5B4FC)),
                                      ),
                                      child: Text(
                                        tr('Active'),
                                        style: GoogleFonts.inter(
                                          color: AppColors.accentDark,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 18),
                                    tooltip: tr('Delete'),
                                    onPressed: () async {
                                      await ChatHistoryService.instance.deleteConversation(conv.id);
                                      setSheetState(() {
                                        recent.removeAt(index);
                                      });
                                      if (isCurrent) {
                                        await _loadChatHistory();
                                      }
                                    },
                                  ),
                                ],
                              ),
                              onTap: () async {
                                Navigator.pop(ctx);
                                await TtsService.instance.stop();
                                await ChatHistoryService.instance.switchConversation(conv.id);
                                final msgs = await ChatHistoryService.instance.loadMessages(conv.id);
                                if (mounted) {
                                  setState(() {
                                    _currentConversation = conv;
                                    _messages.clear();
                                    _messages.addAll(msgs);
                                  });
                                  _scrollToBottom();
                                }
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _askQuick(String question) {
    _controller.text = question;
    _sendMessage();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    AnalyticsService.trackFeature('ai_assistant');
    await TtsService.instance.stop();

    // Ensure conversation exists
    final conv = _currentConversation ??
        await ChatHistoryService.instance.getOrCreateActiveConversation();
    _currentConversation = conv;

    final userMessage = ChatMessage(
      conversationId: conv.id,
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
      language: LocaleService.currentLanguage,
    );

    // Save immediately so it is not lost even if user closes assistant
    await ChatHistoryService.instance.saveMessage(userMessage);

    setState(() {
      _messages.add(userMessage);
      _isSending = true;
    });
    _controller.clear();
    _scrollToBottom();

    final answer = await AssistantService.ask(text);

    final assistantMessage = ChatMessage(
      conversationId: conv.id,
      text: answer.reply,
      isUser: false,
      isOnline: answer.isOnline,
      requiresLogin: answer.requiresLogin,
      timestamp: DateTime.now(),
      language: LocaleService.currentLanguage,
    );

    // Save complete AI response immediately
    await ChatHistoryService.instance.saveMessage(assistantMessage);

    if (mounted) {
      setState(() {
        _messages.add(assistantMessage);
        _isSending = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _openVoiceInput() async {
    final spoken = await showVoiceSearchModal(
      context: context,
      hintText: tr('Ask any legal question in Telugu, Hindi, or English...'),
    );
    if (spoken != null && spoken.isNotEmpty) {
      setState(() {
        _controller.text = spoken;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    TtsService.instance.stop();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LocaleService.language,
      builder: (context, lang, _) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Container(
            color: AppColors.bg,
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  _buildHeader(),
                  ValueListenableBuilder<String?>(
                    valueListenable: AuthService.currentUsername,
                    builder: (context, username, _) {
                      if (username != null) return const SizedBox.shrink();
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        color: AppColors.surface,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                tr('Log in to unlock online AI answers. Offline answers from the LegalGuide library always work.'),
                                style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const LoginScreen()),
                              ),
                              child: Text(tr('Log in'), style: GoogleFonts.inter(color: AppColors.accent, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  Expanded(
                    child: _isLoadingHistory
                        ? const Center(
                            child: CircularProgressIndicator(color: AppColors.accentDark),
                          )
                        : (_messages.isEmpty
                            ? _buildWelcome()
                            : ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(16),
                                itemCount: _messages.length,
                                itemBuilder: (context, index) => _buildBubble(_messages[index]),
                              )),
                  ),
                  if (_isSending)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6366F1)),
                      ),
                    ),
                  _buildInputBar(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: const BoxDecoration(
        color: Color(0xFF4338CA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('LegalGuide Assistant'),
                  softWrap: true,
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  tr('Ask about Indian law, sections & your rights'),
                  maxLines: 2,
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.8), fontSize: 11.5),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.history_rounded, color: Colors.white, size: 21),
            tooltip: tr('Recent Conversations'),
            onPressed: _showHistorySheet,
          ),
          IconButton(
            icon: const Icon(Icons.add_comment_rounded, color: Colors.white, size: 20),
            tooltip: tr('New Chat'),
            onPressed: _startNewChat,
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
            tooltip: tr('Close'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.accent, size: 28),
            ),
            const SizedBox(height: 14),
            Text(tr('Welcome to LegalGuide!'),
                style: GoogleFonts.outfit(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 6),
            Text(
              tr('When you\'re online I can answer anything; offline, I can only use the legal data stored in this app.'),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 18),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in _quickQuestions.entries)
                  ActionChip(
                    label: Text(tr(entry.key)),
                    backgroundColor: AppColors.surface,
                    side: const BorderSide(color: AppColors.border),
                    labelStyle: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 12),
                    onPressed: () => _askQuick(tr(entry.value)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble(ChatMessage message) {
    final isUser = message.isUser;
    if (!isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: AiResponseCard(message: message),
      );
    }

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.80),
        decoration: BoxDecoration(
          color: AppColors.accentDark,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(18),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentDark.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          message.text,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 14.5,
            height: 1.4,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: 40,
                  maxHeight: 140,
                ),
                child: Scrollbar(
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    minLines: 1,
                    maxLines: 6,
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 14.5,
                      height: 1.35,
                    ),
                    decoration: InputDecoration(
                      hintText: tr('Ask your legal question...'),
                      hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13.5),
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      isDense: true,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.mic_rounded, color: AppColors.accentDark, size: 22),
                    tooltip: tr('Speak your question'),
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                    onPressed: _openVoiceInput,
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      color: AppColors.accentDark,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 19),
                      padding: EdgeInsets.zero,
                      tooltip: tr('Send'),
                      onPressed: _isSending ? null : _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
