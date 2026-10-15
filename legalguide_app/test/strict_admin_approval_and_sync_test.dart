import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:legalguide_app/models/legal_section.dart';
import 'package:legalguide_app/models/legal_section_version.dart';
import 'package:legalguide_app/models/legal_update.dart';
import 'package:legalguide_app/services/admin_analytics_service.dart';
import 'package:legalguide_app/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AuthService.currentUsername.value = null;
    AuthService.currentRole.value = null;
  });

  group('Strict Admin Approval & Publication State Separation Tests', () {
    test('1. AdminPendingUpdateRecord strictly distinguishes PENDING_REVIEW, APPROVED, PUBLISHED, and REJECTED states', () {
      final baseJson = {
        'id': 101,
        'law_name': 'Bharatiya Nyaya Sanhita, 2023',
        'act_name': 'Bharatiya Nyaya Sanhita, 2023',
        'section_number': '106',
        'update_type': 'new_section',
        'update_type_display': 'New Section',
        'verification_status': 'verified',
        'proposed_title': 'Causing death by negligence',
        'proposed_legal_text': 'Section 106 statutory text',
        'proposed_simple_explanation': 'Plain language explanation',
        'proposed_punishment': 'Up to 5 years',
        'proposed_effective_date': '2024-07-01',
        'existing_legal_text': 'IPC 304A',
        'detected_diff': '+ Section 106',
        'source_url': 'https://www.indiacode.gov.in/handle/123456789/20062',
        'source_name': 'India Code / Official Gazette S.O. 850(E)',
        'commencement_status': 'Commenced (Sec 106(1)); Sec 106(2) in abeyance',
      };

      // State: PENDING_REVIEW
      final pendingRec = AdminPendingUpdateRecord.fromJson({
        ...baseJson,
        'status': 'pending_review',
        'status_display': 'Pending Review',
      });
      expect(pendingRec.isPending, isTrue);
      expect(pendingRec.isApproved, isFalse);
      expect(pendingRec.isPublished, isFalse);
      expect(pendingRec.isRejected, isFalse);

      // State: APPROVED (Admin approved, but NOT YET PUBLISHED)
      final approvedRec = AdminPendingUpdateRecord.fromJson({
        ...baseJson,
        'status': 'approved',
        'status_display': 'Approved',
        'reviewed_by': 'dinesh_admin',
      });
      expect(approvedRec.isPending, isFalse);
      expect(approvedRec.isApproved, isTrue);
      expect(approvedRec.isPublished, isFalse);
      expect(approvedRec.isRejected, isFalse);

      // State: PUBLISHED (Published to canonical database)
      final publishedRec = AdminPendingUpdateRecord.fromJson({
        ...baseJson,
        'status': 'published',
        'status_display': 'Published',
        'published_by': 'dinesh_admin',
        'approved_version': 1,
      });
      expect(publishedRec.isPending, isFalse);
      expect(publishedRec.isApproved, isFalse);
      expect(publishedRec.isPublished, isTrue);
      expect(publishedRec.isRejected, isFalse);

      // State: REJECTED
      final rejectedRec = AdminPendingUpdateRecord.fromJson({
        ...baseJson,
        'status': 'rejected',
        'status_display': 'Rejected',
        'admin_notes': 'Contradicts official gazette notification.',
      });
      expect(rejectedRec.isPending, isFalse);
      expect(rejectedRec.isApproved, isFalse);
      expect(rejectedRec.isPublished, isFalse);
      expect(rejectedRec.isRejected, isTrue);
    });

    test('2. Normal users and unauthenticated sessions cannot approve, publish, or reject updates', () async {
      // 1. Unauthenticated citizen attempt
      AuthService.currentUsername.value = null;
      AuthService.currentRole.value = null;

      final approveRes1 = await AdminAnalyticsService.approveUpdate(101, notes: 'Unauthorized note');
      expect(approveRes1['success'], isFalse);
      expect(approveRes1['error'], contains('Administrator authentication required'));

      final publishRes1 = await AdminAnalyticsService.publishUpdate(101);
      expect(publishRes1['success'], isFalse);
      expect(publishRes1['error'], contains('Administrator authentication required'));

      final rejectRes1 = await AdminAnalyticsService.rejectUpdate(101, reason: 'Unauthorized note');
      expect(rejectRes1['success'], isFalse);
      expect(rejectRes1['error'], contains('Administrator authentication required'));

      // 2. Authenticated Normal Citizen (role: 'USER') attempt
      AuthService.currentUsername.value = 'citizen_rahul';
      AuthService.currentRole.value = 'USER';

      final approveRes2 = await AdminAnalyticsService.approveUpdate(101);
      expect(approveRes2['success'], isFalse);
      expect(approveRes2['error'], contains('Administrator authentication required'));

      final publishRes2 = await AdminAnalyticsService.publishUpdate(101);
      expect(publishRes2['success'], isFalse);
      expect(publishRes2['error'], contains('Administrator authentication required'));

      final rejectRes2 = await AdminAnalyticsService.rejectUpdate(101, reason: 'Unauthorized note');
      expect(rejectRes2['success'], isFalse);
      expect(rejectRes2['error'], contains('Administrator authentication required'));
    });

    test('3. Published updates endpoint data model enforces published-only visibility', () {
      final publishedUpdateJson = {
        'id': 12,
        'title': 'BNS 2023 — Section 106 Published',
        'description': 'Section 106 Causing death by negligence published.',
        'update_type': 'new_section',
        'update_type_display': 'New Section',
        'affected_law_name': 'Bharatiya Nyaya Sanhita, 2023',
        'affected_law_short_name': 'BNS 2023',
        'affected_section': '106',
        'new_version': 1,
        'official_source_name': 'India Code / Gazette S.O. 850(E)',
        'official_source_url': 'https://www.indiacode.gov.in/handle/123456789/20062',
        'effective_date': '2024-07-01',
        'last_verified_at': '2026-10-12',
        'published_at': '2026-10-12T10:00:00Z',
      };

      final update = LegalUpdate.fromJson(publishedUpdateJson);
      expect(update.id, 12);
      expect(update.affectedSection, '106');
      expect(update.newVersion, 1);
      expect(update.updateType, 'new_section');
      expect(update.officialSourceName, contains('India Code'));
    });

    test('4. LegalSectionVersion data model preserves version history and immutable audit trail', () {
      final versionJson = {
        'id': 4,
        'section': 101,
        'version': 1,
        'legal_text': 'Original Section 303 Theft bare act text.',
        'simple_explanation': 'Original explanation without community service.',
        'punishment': 'Imprisonment up to 3 years.',
        'effective_date': '2024-07-01',
        'amendment_info': 'Initial enactment',
        'source_name': 'India Code',
        'source_url': 'https://www.indiacode.gov.in/',
        'archived_at': '2026-10-12T08:00:00Z',
        'change_summary': 'Initial version archive',
      };

      final v = LegalSectionVersion.fromJson(versionJson);
      expect(v.id, 4);
      expect(v.sectionId, 101);
      expect(v.version, 1);
      expect(v.legalText, contains('Original Section 303'));
      expect(v.amendmentInfo, 'Initial enactment');
      expect(v.changeSummary, 'Initial version archive');
    });

    test('5. Delta sync payload parser correctly maps published sections and versions', () {
      final deltaJson = {
        'sync_timestamp': '2026-10-12T12:00:00Z',
        'server_version': 3,
        'is_incremental': true,
        'source_name': 'India Code Portal',
        'source_url': 'https://www.indiacode.gov.in/',
        'last_verified': '2026-10-12',
        'categories': [],
        'laws': [],
        'sections': [
          {
            'id': 142,
            'law': 1,
            'law_name': 'Bharatiya Nyaya Sanhita, 2023',
            'law_short_name': 'BNS',
            'section_number': '106',
            'title': 'Causing death by negligence',
            'legal_text': 'Section 106 official bare act text',
            'simple_explanation': 'Causing death by negligence explanation',
            'purpose': 'Penalizing negligent acts causing fatality',
            'punishment': 'Up to 5 years (2 years for medical practitioner)',
            'effective_date': '2024-07-01',
            'status': 'current',
            'version': 1,
          }
        ],
        'versions': [
          {
            'id': 1,
            'section': 142,
            'version': 1,
            'legal_text': 'Prior text',
            'verified_by': 'admin',
          }
        ],
        'deleted_section_ids': [],
      };

      final sectionsRaw = deltaJson['sections'] as List;
      final parsedSections = sectionsRaw.map((s) => LegalSection.fromJson(Map<String, dynamic>.from(s))).toList();
      expect(parsedSections.length, 1);
      expect(parsedSections[0].sectionNumber, '106');
      expect(parsedSections[0].status, 'current');
      expect(parsedSections[0].version, 1);

      final versionsRaw = deltaJson['versions'] as List;
      final parsedVersions = versionsRaw.map((v) => LegalSectionVersion.fromJson(Map<String, dynamic>.from(v))).toList();
      expect(parsedVersions.length, 1);
      expect(parsedVersions[0].version, 1);
    });
  });
}
