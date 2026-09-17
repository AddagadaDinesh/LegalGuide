import 'package:flutter/material.dart';
import '../models/legal_section.dart';

/// Maps a section's actual title/keywords to a specific illustrative icon,
/// falling back to a generic scale-of-justice icon if nothing matches.
/// This is a rendered graphic, not a sourced photo/video — it exists so a
/// section has a quick visual identity even for someone who won't read
/// the full text.
IconData sectionIconFor(LegalSection section) {
  final haystack = '${section.title} ${section.keywords}'.toLowerCase();

  const rules = <MapEntry<List<String>, IconData>>[
    MapEntry(['arrest', 'detain', 'custody', 'warrant'], Icons.local_police_rounded),
    MapEntry(['bail'], Icons.gavel_rounded),
    MapEntry(['murder', 'hurt', 'assault', 'injury', 'modesty'], Icons.health_and_safety_rounded),
    MapEntry(['theft', 'snatching', 'robbery', 'stealing'], Icons.no_backpack_rounded),
    MapEntry(['cheat', 'fraud', 'scam', 'breach of trust'], Icons.currency_exchange_rounded),
    MapEntry(['intimidation', 'threat', 'blackmail'], Icons.warning_amber_rounded),
    MapEntry(['defamation', 'reputation'], Icons.record_voice_over_rounded),
    MapEntry(['cyber', 'identity theft', 'password', 'hack', 'phishing', 'otp'], Icons.security_rounded),
    MapEntry(['divorce', 'marriage', 'maintenance'], Icons.family_restroom_rounded),
    MapEntry(['domestic violence', 'protection order'], Icons.shield_rounded),
    MapEntry(['property', 'sale deed', 'mortgage', 'registration', 'land'], Icons.home_work_rounded),
    MapEntry(['consumer', 'refund', 'defective', 'warranty'], Icons.shopping_cart_rounded),
    MapEntry(['drunk driving', 'traffic', 'vehicle', 'license', 'accident'], Icons.directions_car_rounded),
    MapEntry(['dowry'], Icons.report_problem_rounded),
    MapEntry(['harassment', 'workplace'], Icons.groups_rounded),
    MapEntry(['child', 'pocso', 'juvenile'], Icons.child_care_rounded),
    MapEntry(['maternity', 'labour', 'wages', 'employment', 'retrenchment'], Icons.work_rounded),
    MapEntry(['constitution', 'article', 'fundamental right', 'equality', 'liberty'], Icons.account_balance_rounded),
    MapEntry(['lawyer', 'legal counsel', 'legal aid'], Icons.balance_rounded),
  ];

  for (final rule in rules) {
    if (rule.key.any(haystack.contains)) return rule.value;
  }
  return Icons.balance_rounded;
}
