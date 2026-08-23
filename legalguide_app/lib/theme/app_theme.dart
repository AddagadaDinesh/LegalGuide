import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFF0B1120);
  static const surface = Color(0xFF1A2436);
  static const surfaceRaised = Color(0xFF212D42);
  static const border = Color(0xFF2E3B52);
  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xFF9AACC4);
  static const textMuted = Color(0xFF64748B);
  static const accent = Color(0xFF6366F1);
  static const accentDark = Color(0xFF4338CA);
  static const accentLight = Color(0xFF818CF8);
  static const success = Color(0xFF34D399);
  static const warning = Color(0xFFFBBF24);
  static const danger = Color(0xFFF87171);

  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, Color(0xFF8B5CF6)],
  );
}

class CategoryStyle {
  final Color color;
  final IconData icon;
  const CategoryStyle(this.color, this.icon);
}

const _categoryStyles = <String, CategoryStyle>{
  'Criminal Law': CategoryStyle(Color(0xFFF43F5E), Icons.gavel_rounded),
  'Constitutional Law': CategoryStyle(Color(0xFF3B82F6), Icons.account_balance_rounded),
  'Arrest & Detention': CategoryStyle(Color(0xFFF59E0B), Icons.local_police_rounded),
  'Family Law': CategoryStyle(Color(0xFFEC4899), Icons.family_restroom_rounded),
  'Property Law': CategoryStyle(Color(0xFF14B8A6), Icons.home_work_rounded),
  'Consumer Law': CategoryStyle(Color(0xFFFB923C), Icons.shopping_cart_rounded),
  'Motor Vehicle Law': CategoryStyle(Color(0xFF22D3EE), Icons.directions_car_rounded),
  "Women's Rights": CategoryStyle(Color(0xFFD946EF), Icons.volunteer_activism_rounded),
  'Child Protection': CategoryStyle(Color(0xFF84CC16), Icons.child_care_rounded),
  'Labour & Employment': CategoryStyle(Color(0xFF818CF8), Icons.work_rounded),
  'Cyber Law': CategoryStyle(Color(0xFFA78BFA), Icons.security_rounded),
};

const _defaultCategoryStyle = CategoryStyle(AppColors.accent, Icons.balance_rounded);

CategoryStyle categoryStyleFor(String categoryName) =>
    _categoryStyles[categoryName] ?? _defaultCategoryStyle;

class AppRadius {
  static const card = 18.0;
  static const chip = 12.0;
  static const pill = 100.0;
}
