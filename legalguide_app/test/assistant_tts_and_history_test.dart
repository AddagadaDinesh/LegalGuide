import 'package:flutter_test/flutter_test.dart';
import 'package:legalguide_app/models/chat_message.dart';
import 'package:legalguide_app/models/conversation.dart';
import 'package:legalguide_app/services/chat_history_service.dart';

void main() {
  group('ChatMessage & Conversation Model Tests', () {
    test('ChatMessage serializes to and from Map correctly', () {
      final now = DateTime(2026, 9, 28, 20, 30);
      final msg = ChatMessage(
        id: 'msg_001',
        conversationId: 'conv_123',
        role: 'user',
        text: 'What are my rights during arrest?',
        isUser: true,
        isOnline: true,
        requiresLogin: false,
        timestamp: now,
        language: 'en',
      );

      final map = msg.toMap();
      expect(map['id'], 'msg_001');
      expect(map['conversation_id'], 'conv_123');
      expect(map['role'], 'user');
      expect(map['message'], 'What are my rights during arrest?');
      expect(map['is_user'], 1);
      expect(map['is_online'], 1);
      expect(map['requires_login'], 0);
      expect(map['language'], 'en');

      final fromMap = ChatMessage.fromMap(map);
      expect(fromMap.id, 'msg_001');
      expect(fromMap.conversationId, 'conv_123');
      expect(fromMap.role, 'user');
      expect(fromMap.text, 'What are my rights during arrest?');
      expect(fromMap.isUser, true);
      expect(fromMap.isOnline, true);
      expect(fromMap.requiresLogin, false);
      expect(fromMap.language, 'en');
    });

    test('Conversation serializes to and from Map correctly', () {
      final created = DateTime(2026, 9, 28, 10, 0);
      final updated = DateTime(2026, 9, 28, 10, 30);
      final conv = Conversation(
        id: 'conv_100',
        title: 'Arrest Rights',
        createdAt: created,
        updatedAt: updated,
        language: 'te',
        isActive: true,
      );

      final map = conv.toMap();
      expect(map['id'], 'conv_100');
      expect(map['title'], 'Arrest Rights');
      expect(map['language'], 'te');
      expect(map['is_active'], 1);

      final fromMap = Conversation.fromMap(map);
      expect(fromMap.id, 'conv_100');
      expect(fromMap.title, 'Arrest Rights');
      expect(fromMap.language, 'te');
      expect(fromMap.isActive, true);
    });
  });

  group('ChatHistoryService Title Generation Tests', () {
    test('Generates clean titles from common question formats', () {
      expect(
        ChatHistoryService.generateTitleFromQuestion('What are my rights during arrest?'),
        'My rights during arrest',
      );
      expect(
        ChatHistoryService.generateTitleFromQuestion('What is theft under BNS?'),
        'Theft under BNS',
      );
      expect(
        ChatHistoryService.generateTitleFromQuestion('How can I contest a traffic challan?'),
        'Contest a traffic challan',
      );
      expect(
        ChatHistoryService.generateTitleFromQuestion('Can you explain section 303?'),
        'Section 303',
      );
      expect(
        ChatHistoryService.generateTitleFromQuestion('Where is Buddha statue in Hyderabad?'),
        'Where is Buddha statue in Hyderabad',
      );
      expect(
        ChatHistoryService.generateTitleFromQuestion('అరెస్ట్ సమయంలో నా హక్కులు ఏమిటి?'),
        'అరెస్ట్ సమయంలో నా హక్కులు ఏమిటి',
      );
      expect(
        ChatHistoryService.generateTitleFromQuestion('गिरफ्तारी के दौरान मेरे अधिकार क्या हैं?'),
        'गिरफ्तारी के दौरान मेरे अधिकार क्या...',
      );
    });
  });
}
