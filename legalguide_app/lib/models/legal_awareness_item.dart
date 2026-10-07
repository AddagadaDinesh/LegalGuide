import 'package:flutter/material.dart';

/// Model representing an individual practical legal-awareness topic
/// housed inside the scalable "Legal Awareness" parent section.
class LegalAwarenessItem {
  final String id;
  final String title;
  final String subtitle;
  final String? badge;
  final IconData icon;
  final Color accentColor;
  final List<Color> gradientColors;
  final Color shadowColor;
  final WidgetBuilder screenBuilder;
  final String category;
  final bool enabled;
  final int order;

  const LegalAwarenessItem({
    required this.id,
    required this.title,
    required this.subtitle,
    this.badge,
    required this.icon,
    this.accentColor = const Color(0xFF6366F1),
    this.gradientColors = const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    this.shadowColor = const Color(0xFF6366F1),
    required this.screenBuilder,
    this.category = 'Legal Awareness',
    this.enabled = true,
    this.order = 0,
  });

  /// Alias for subtitle for clean data-driven access
  String get description => subtitle;
}
