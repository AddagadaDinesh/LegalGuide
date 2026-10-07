import '../models/chat_message.dart';
import '../models/conversation.dart';
import 'locale_service.dart';
import 'sqlite_legal_db.dart';

class ChatHistoryService {
  ChatHistoryService._();
  static final ChatHistoryService instance = ChatHistoryService._();

  /// Retrieves the currently active conversation or creates a new one.
  Future<Conversation> getOrCreateActiveConversation({String? language}) async {
    final active = await SqliteLegalDb.getActiveConversation();
    if (active != null) return active;

    final newConv = Conversation(
      id: 'conv_${DateTime.now().millisecondsSinceEpoch}',
      title: 'New Conversation',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      language: language ?? LocaleService.currentLanguage,
      isActive: true,
    );
    await SqliteLegalDb.saveConversation(newConv);
    return newConv;
  }

  /// Explicitly starts a new conversation, setting previous active to false.
  Future<Conversation> startNewConversation({String? language}) async {
    final newConv = Conversation(
      id: 'conv_${DateTime.now().millisecondsSinceEpoch}',
      title: 'New Conversation',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      language: language ?? LocaleService.currentLanguage,
      isActive: true,
    );
    await SqliteLegalDb.setActiveConversation('');
    await SqliteLegalDb.saveConversation(newConv);
    return newConv;
  }

  /// Loads all messages for a specific conversation.
  Future<List<ChatMessage>> loadMessages(String conversationId) async {
    return await SqliteLegalDb.getMessagesForConversation(conversationId);
  }

  /// Saves a chat message and automatically updates conversation title on first question.
  Future<void> saveMessage(ChatMessage message) async {
    await SqliteLegalDb.saveChatMessage(message);

    if (message.isUser) {
      try {
        final convs = await SqliteLegalDb.getConversations(limit: 50);
        final conv = convs.firstWhere(
          (c) => c.id == message.conversationId,
          orElse: () => Conversation(
            id: message.conversationId,
            title: 'New Conversation',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            language: message.language,
          ),
        );
        if (conv.title == 'New Conversation' ||
            conv.title == 'New Chat' ||
            conv.title.startsWith('New ')) {
          final title = generateTitleFromQuestion(message.text);
          if (title.isNotEmpty) {
            await SqliteLegalDb.updateConversationTitle(message.conversationId, title);
          }
        }
      } catch (_) {}
    }
  }

  /// Retrieves list of recent conversations for the history viewer.
  Future<List<Conversation>> getRecentConversations({int limit = 30}) async {
    return await SqliteLegalDb.getConversations(limit: limit);
  }

  /// Switches active conversation to the specified [conversationId].
  Future<void> switchConversation(String conversationId) async {
    await SqliteLegalDb.setActiveConversation(conversationId);
  }

  /// Deletes a conversation and its messages.
  Future<void> deleteConversation(String conversationId) async {
    await SqliteLegalDb.deleteConversation(conversationId);
  }

  /// Generates a clean, readable conversation title from the initial user question.
  static String generateTitleFromQuestion(String question) {
    var q = question.trim();
    final prefixes = [
      RegExp(r'^what\s+(?:is|are|does)\s+(?:the\s+)?', caseSensitive: false),
      RegExp(r'^how\s+(?:can\s+i|to|do\s+i)\s+', caseSensitive: false),
      RegExp(r'^can\s+you\s+(?:explain|tell\s+me)\s+(?:about\s+)?', caseSensitive: false),
      RegExp(r'^tell\s+me\s+about\s+', caseSensitive: false),
      RegExp(r'^i\s+want\s+to\s+know\s+about\s+', caseSensitive: false),
      RegExp(r'^please\s+explain\s+', caseSensitive: false),
    ];
    for (final p in prefixes) {
      if (p.hasMatch(q)) {
        q = q.replaceFirst(p, '').trim();
        break;
      }
    }
    q = q.replaceAll(RegExp(r'[?.!]+$'), '').trim();
    if (q.isEmpty) return 'Legal Inquiry';
    q = q[0].toUpperCase() + (q.length > 1 ? q.substring(1) : '');
    if (q.length > 38) {
      q = '${q.substring(0, 35)}...';
    }
    return q;
  }
}
