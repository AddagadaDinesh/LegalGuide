import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:legalguide_app/services/admin_analytics_service.dart';

void main() {
  test('AdminPendingUpdateRecord parses production BNS Section 106 update json cleanly', () {
    const rawJson = '''
    {
      "id": 1,
      "law_name": "Bharatiya Nyaya Sanhita, 2023",
      "update_type_display": "Amendment / Changed Section",
      "status_display": "Pending Review",
      "act_name": "Bharatiya Nyaya Sanhita, 2023",
      "section_number": "106",
      "update_type": "amendment",
      "status": "pending_review",
      "verification_status": "verified",
      "proposed_title": "Causing death by negligence",
      "proposed_legal_text": "Section 106 text",
      "proposed_simple_explanation": "Section 106 explanation",
      "proposed_punishment": "Up to 5 years",
      "proposed_effective_date": "2024-07-01",
      "proposed_amendment_info": "MHA Notification",
      "existing_legal_text": "IPC 304A",
      "detected_diff": "+ diff",
      "source_url": "https://www.indiacode.gov.in/handle/123456789/20062",
      "source_name": "India Code",
      "source_publication_date": "2024-02-23",
      "commencement_status": "Commenced",
      "detected_at": "2026-10-11T05:13:31.700015Z",
      "reviewed_at": null,
      "reviewed_by": "",
      "verified_at": null,
      "verified_by": "",
      "published_at": null,
      "published_by": "",
      "admin_notes": "",
      "previous_version": null,
      "approved_version": null,
      "section": null,
      "law": 1
    }
    ''';

    final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
    final record = AdminPendingUpdateRecord.fromJson(decoded);

    expect(record.id, 1);
    expect(record.sectionNumber, '106');
    expect(record.actName, 'Bharatiya Nyaya Sanhita, 2023');
    expect(record.status, 'pending_review');
    expect(record.isPending, isTrue);
    expect(record.isApproved, isFalse);
    expect(record.isPublished, isFalse);
  });
}
