import 'package:flutter/material.dart';
import '../models/legal_awareness_item.dart';
import '../screens/emergency_guide_screen.dart';
import '../screens/railway_rules_screen.dart';
import '../screens/traffic_rules_screen.dart';

/// Registry and repository for practical legal-awareness topics.
///
/// "Legal Awareness" acts as a scalable parent container.
/// Future everyday legal topics (e.g., Airline & Aviation Laws, Consumer Rights,
/// Tenant & Rental Rules, Patient Rights, Workplace Rights) are added directly
/// to this registry and will automatically render inside the "Legal Awareness"
/// screen without modifying the Home screen layout.
class LegalAwarenessData {
  LegalAwarenessData._();

  static final List<LegalAwarenessItem> _initialItems = [
    LegalAwarenessItem(
      id: 'emergency_rights',
      title: 'Emergency Rights Guide',
      subtitle: "Police stops, traffic challans, cyber fraud & women's safety rights",
      badge: 'HELP NOW',
      icon: Icons.shield_rounded,
      accentColor: const Color(0xFFDC2626),
      gradientColors: const [Color(0xFF881337), Color(0xFFDC2626)],
      shadowColor: const Color(0xFFDC2626),
      screenBuilder: (_) => const EmergencyGuideScreen(),
      category: 'Legal Awareness',
      enabled: true,
      order: 1,
    ),
    LegalAwarenessItem(
      id: 'railway_rules',
      title: 'Indian Railway Rules & Fines',
      subtitle: 'Penalties, ticketless travel, chain pulling & passenger rights',
      icon: Icons.train_rounded,
      accentColor: const Color(0xFF0284C7),
      gradientColors: const [Color(0xFF0369A1), Color(0xFF0284C7)],
      shadowColor: const Color(0xFF0284C7),
      screenBuilder: (_) => const RailwayRulesScreen(),
      category: 'Legal Awareness',
      enabled: true,
      order: 2,
    ),
    LegalAwarenessItem(
      id: 'traffic_rules',
      title: 'Traffic Rules & Driver Rights',
      subtitle: 'MV Act fines, e-challan disputes & citizen driver protections',
      icon: Icons.traffic_rounded,
      accentColor: const Color(0xFFD97706),
      gradientColors: const [Color(0xFFB45309), Color(0xFFD97706)],
      shadowColor: const Color(0xFFD97706),
      screenBuilder: (_) => const TrafficRulesScreen(),
      category: 'Legal Awareness',
      enabled: true,
      order: 3,
    ),
  ];

  static List<LegalAwarenessItem> _items = List.from(_initialItems);

  /// All registered items
  static List<LegalAwarenessItem> get items => List.unmodifiable(_items);

  /// Returns sorted, enabled items for normal citizen display
  static List<LegalAwarenessItem> get activeItems {
    final list = _items.where((item) => item.enabled).toList();
    list.sort((a, b) => a.order.compareTo(b.order));
    return list;
  }

  /// Dynamically register or update an awareness item
  static void registerItem(LegalAwarenessItem item) {
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index >= 0) {
      _items[index] = item;
    } else {
      _items.add(item);
    }
  }

  /// Dynamically toggle item enabled status
  static void setItemEnabled(String id, bool enabled) {
    final index = _items.indexWhere((i) => i.id == id);
    if (index >= 0) {
      final old = _items[index];
      _items[index] = LegalAwarenessItem(
        id: old.id,
        title: old.title,
        subtitle: old.subtitle,
        badge: old.badge,
        icon: old.icon,
        accentColor: old.accentColor,
        gradientColors: old.gradientColors,
        shadowColor: old.shadowColor,
        screenBuilder: old.screenBuilder,
        category: old.category,
        enabled: enabled,
        order: old.order,
      );
    }
  }

  /// Reset to initial defaults (useful for testing)
  static void resetToDefaults() {
    _items = List.from(_initialItems);
  }

  /// Find an awareness topic by its unique ID.
  static LegalAwarenessItem? findById(String id) {
    try {
      return _items.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }
}
