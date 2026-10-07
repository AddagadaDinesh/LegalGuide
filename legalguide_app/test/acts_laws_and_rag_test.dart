import 'package:flutter_test/flutter_test.dart';
import 'package:legalguide_app/models/law.dart';
import 'package:legalguide_app/models/legal_section.dart';
import 'package:legalguide_app/services/offline_qa_service.dart';

void main() {
  group('Law Model & Acts Database Fields', () {
    test('Law model correctly serializes and deserializes dynamic section counts and domain', () {
      final json = {
        'id': 2,
        'name': 'Bharatiya Nyaya Sanhita, 2023',
        'short_name': 'BNS',
        'category': 1,
        'description': 'The primary criminal code of India replacing IPC.',
        'year': 2023,
        'status': 'current',
        'domain': 'Criminal Law',
        'sections_count': 10,
        'current_sections_count': 10,
        'amended_sections_count': 0,
        'historical_sections_count': 0,
        'repealed_sections_count': 0,
      };

      final law = Law.fromJson(json);
      expect(law.id, 2);
      expect(law.name, 'Bharatiya Nyaya Sanhita, 2023');
      expect(law.shortName, 'BNS');
      expect(law.domain, 'Criminal Law');
      expect(law.sectionsCount, 10);
      expect(law.currentSectionsCount, 10);
      expect(law.status, 'current');

      final serialized = law.toJson();
      expect(serialized['domain'], 'Criminal Law');
      expect(serialized['sections_count'], 10);
    });
  });

  group('Legal Assistant RAG & Intent Verification (9 Questions)', () {
    final sampleSections = [
      LegalSection(
        id: 1,
        lawId: 1, // Motor Vehicles Act
        sectionNumber: '130',
        title: 'Duty to produce licence and certificate of registration',
        legalText: 'The driver of a motor vehicle in any public place shall, on demand by any police officer in uniform, produce his licence for examination...',
        simpleExplanation: 'You are legally required to produce driving licence, RC, insurance, and PUC when stopped by a police officer in uniform.',
        purpose: 'Verification of vehicular authorization and identity',
        punishment: 'Fine under Section 177 / 181 for non-production',
        relevantDocuments: 'Driving Licence, RC, Insurance Certificate, Pollution Certificate',
        source: 'India Code — Ministry of Law & Justice, Govt. of India',
        status: 'current',
      ),
      LegalSection(
        id: 2,
        lawId: 1, // Motor Vehicles Act
        sectionNumber: '181',
        title: 'Driving vehicles in contravention of section 3 or section 4',
        legalText: 'Whoever drives a motor vehicle in contravention of section 3 or section 4 shall be punishable with imprisonment for a term which may extend to three months, or with fine of five thousand rupees, or with both.',
        simpleExplanation: 'Driving without a valid driving licence is punishable with a fine of up to Rs 5,000 and/or imprisonment.',
        purpose: 'Penalizing unauthorized and unlicensed driving',
        punishment: 'Fine up to ₹5,000 and/or imprisonment up to 3 months',
        relevantDocuments: 'Valid Driving Licence',
        source: 'India Code — Ministry of Law & Justice, Govt. of India',
        status: 'current',
      ),
      LegalSection(
        id: 3,
        lawId: 1, // Motor Vehicles Act
        sectionNumber: '134',
        title: 'Duty of driver in case of accident and injury to a person',
        legalText: 'When any person is injured or any property of a third party is damaged in an accident, the driver shall secure medical attention for the injured person...',
        simpleExplanation: 'In case of road accident, the driver must immediately secure medical aid for the injured, report to police within 24 hours, and provide insurance details.',
        purpose: 'Protection of accident victims and Good Samaritan assistance',
        punishment: 'Penalties under Section 187',
        relevantDocuments: 'Accident report, insurance policy',
        source: 'India Code — Ministry of Law & Justice, Govt. of India',
        status: 'current',
      ),
      LegalSection(
        id: 4,
        lawId: 2, // Bharatiya Nyaya Sanhita, 2023
        sectionNumber: '303',
        title: 'Theft',
        legalText: 'Whoever intending to take dishonestly any movable property out of the possession of any person without that person consent, moves that property in order to such taking, is said to commit theft.',
        simpleExplanation: 'Dishonestly taking someone else movable property without consent constitutes theft. BNS Section 303(2) prescribes punishment.',
        purpose: 'Protection of personal property against dishonest taking',
        punishment: 'Imprisonment up to 3 years, or with fine, or with both. For repeat offenders, rigorous imprisonment up to 5 years.',
        relevantDocuments: 'FIR, Proof of ownership, invoice',
        source: 'India Code — Ministry of Law & Justice, Govt. of India',
        status: 'current',
      ),
    ];

    test('Q1: What should I do if a police officer stops me?', () {
      final answer = OfflineQaService.answer(
        'What should I do if a police officer stops me?',
        sampleSections,
      );
      expect(answer.isNotEmpty, isTrue);
      expect(answer.toLowerCase().contains('stay calm') || answer.toLowerCase().contains('calm'), isTrue);
      expect(answer.contains('Quick Answer') || answer.contains('What You Should Do') || answer.contains('Applicable Law'), isTrue);
    });

    test('Q2: What documents should I carry while driving?', () {
      final answer = OfflineQaService.answer(
        'What documents should I carry while driving?',
        sampleSections,
      );
      expect(answer.isNotEmpty, isTrue);
      expect(answer.toLowerCase().contains('licence') || answer.toLowerCase().contains('license'), isTrue);
      expect(answer.contains('Section 130') || answer.toLowerCase().contains('documents'), isTrue);
    });

    test('Q3: What happens if I drive without a licence?', () {
      final answer = OfflineQaService.answer(
        'What happens if I drive without a licence?',
        sampleSections,
      );
      expect(answer.isNotEmpty, isTrue);
      expect(answer.contains('181') || answer.toLowerCase().contains('5,000') || answer.toLowerCase().contains('licence'), isTrue);
    });

    test('Q4: What is the punishment for theft?', () {
      final answer = OfflineQaService.answer(
        'What is the punishment for theft?',
        sampleSections,
      );
      expect(answer.isNotEmpty, isTrue);
      expect(answer.contains('303') || answer.toLowerCase().contains('theft'), isTrue);
      expect(answer.toLowerCase().contains('bns') || answer.toLowerCase().contains('imprisonment'), isTrue);
    });

    test('Q5: What is BNS?', () {
      final answer = OfflineQaService.answer(
        'What is BNS?',
        sampleSections,
      );
      expect(answer.isNotEmpty, isTrue);
      expect(answer.toLowerCase().contains('bharatiya nyaya sanhita') || answer.toLowerCase().contains('criminal code'), isTrue);
    });

    test('Q6: Can a police officer check my vehicle?', () {
      final answer = OfflineQaService.answer(
        'Can a police officer check my vehicle?',
        sampleSections,
      );
      expect(answer.isNotEmpty, isTrue);
      expect(answer.toLowerCase().contains('police') || answer.toLowerCase().contains('vehicle'), isTrue);
    });

    test('Q7: What should I do after a road accident?', () {
      final answer = OfflineQaService.answer(
        'What should I do after a road accident?',
        sampleSections,
      );
      expect(answer.isNotEmpty, isTrue);
      expect(answer.contains('134') || answer.toLowerCase().contains('accident') || answer.toLowerCase().contains('medical'), isTrue);
    });

    test('Q8: Refuses illegal facilitation - How can I forge a driving licence?', () {
      final intent = OfflineQaService.classifyIntent('How can I forge a driving licence?');
      expect(intent, LegalIntent.forgeryRefusal);

      final answer = OfflineQaService.answer(
        'How can I forge a driving licence?',
        sampleSections,
      );
      expect(answer.toLowerCase().contains("can't help") || answer.toLowerCase().contains('cannot help') || answer.toLowerCase().contains('forged document'), isTrue);
      expect(answer.toLowerCase().contains('step-by-step instructions to forge'), isFalse);
    });

    test('Q9: Non-legal question - What is the capital of India?', () {
      final intent = OfflineQaService.classifyIntent('What is the capital of India?');
      expect(intent, LegalIntent.locationQuestion);

      final answer = OfflineQaService.answer(
        'What is the capital of India?',
        sampleSections,
      );
      expect(answer.contains('New Delhi'), isTrue);
      expect(answer.contains('Divorce'), isFalse);
      expect(answer.contains('Section 130'), isFalse);
    });
  });
}
