import 'package:flutter_test/flutter_test.dart';
import 'package:legalguide_app/models/legal_section.dart';
import 'package:legalguide_app/services/offline_qa_service.dart';

void main() {
  test('Non-legal question about Buddha statue should not return divorce or Section 13', () {
    final sections = [
      LegalSection(
        id: 1,
        lawId: 8, // Hindu Marriage Act
        sectionNumber: '13',
        title: 'Divorce',
        legalText: 'Any marriage solemnized...',
        simpleExplanation: 'Provides grounds for obtaining a decree of divorce.',
        purpose: 'Dissolution of marriage',
        punishment: 'None (Civil remedy)',
        relevantDocuments: 'Marriage certificate, evidence',
        source: 'India Code',
      ),
      LegalSection(
        id: 2,
        lawId: 2, // BNS
        sectionNumber: '103',
        title: 'Punishment for Murder',
        legalText: 'Whoever commits murder...',
        simpleExplanation: 'Prescribes punishment for murder.',
        purpose: 'Penalizing intentional killing',
        punishment: 'Death or imprisonment for life, and fine',
        relevantDocuments: 'FIR, Post-mortem report',
        source: 'India Code',
        previousVersionRef: 'Replaces IPC Section 302',
      ),
    ];

    // 1. User's exact prompt
    final reply1 = OfflineQaService.answer('What is the section for Buddha statue in Hyderabad?', sections);
    expect(reply1.contains('Divorce'), isFalse);
    expect(reply1.contains('Section 13'), isFalse);
    expect(reply1.toLowerCase().contains('legal question'), isTrue);

    // 2. Location question
    final reply2 = OfflineQaService.answer('Where is the Buddha statue in Hyderabad?', sections);
    expect(reply2.contains('Divorce'), isFalse);
    expect(reply2.contains('Section 13'), isFalse);
    expect(reply2.toLowerCase().contains('legal question'), isTrue);

    // 3. Vague question asking for clarification
    final reply3 = OfflineQaService.answer('My neighbour is troubling me', sections);
    expect(reply3.contains('What is your neighbour doing'), isTrue);

    // 4. IPC 302 query maps to BNS 103
    final reply4 = OfflineQaService.answer('What is IPC Section 302?', sections);
    expect(reply4.contains('BNS'), isTrue);
    expect(reply4.contains('103'), isTrue);
  });
}
