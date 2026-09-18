import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../localization/app_strings.dart';
import '../models/chat_message.dart';
import '../services/assistant_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
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
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  void _askQuick(String question) {
    _controller.text = question;
    _sendMessage();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true, timestamp: DateTime.now()));
      _isSending = true;
    });
    _controller.clear();
    _scrollToBottom();

    final answer = await AssistantService.ask(text);

    setState(() {
      _messages.add(ChatMessage(
        text: answer.reply,
        isUser: false,
        isOnline: answer.isOnline,
        requiresLogin: answer.requiresLogin,
        timestamp: DateTime.now(),
      ));
      _isSending = false;
    });
    _scrollToBottom();
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
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                child: _messages.isEmpty
                    ? _buildWelcome()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) => _buildBubble(_messages[index]),
                      ),
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
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
      decoration: const BoxDecoration(
        color: Color(0xFF4338CA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('LegalGuide Assistant'),
                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text(tr('Ask about Indian law, sections & your rights'),
                    style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
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
                    onPressed: () => _askQuick(entry.value),
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
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: isUser ? AppColors.accent : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: isUser ? null : Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser && message.requiresLogin)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF334155),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tr('🔒 Log in or create an account for answers beyond app content'),
                    style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 11),
                  ),
                ),
              )
            else if (!isUser && message.isOnline == false)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF334155),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tr('🟠 Offline – Using LegalGuide Knowledge'),
                    style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 11),
                  ),
                ),
              ),
            if (!isUser && message.isOnline == true)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF854D0E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tr('🟢 Online'),
                    style: GoogleFonts.inter(color: const Color(0xFFFDE68A), fontSize: 11),
                  ),
                ),
              ),
            Text(
              message.text,
              style: GoogleFonts.inter(
                color: isUser ? Colors.white : AppColors.textPrimary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            if (!isUser && message.requiresLogin)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  ),
                  child: Text(
                    tr('Log in or create an account →'),
                    style: GoogleFonts.inter(color: AppColors.accent, fontWeight: FontWeight.w600, fontSize: 12.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: GoogleFonts.inter(color: AppColors.textPrimary),
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: tr('Ask a question...'),
                hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white),
              onPressed: _isSending ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
