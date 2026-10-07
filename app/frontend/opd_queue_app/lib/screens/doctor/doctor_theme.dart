import 'package:flutter/material.dart';

class DoctorTheme {
  // Primary medical teal matching login & patient theme
  static const Color primary = Color(0xFF1A5C6B);
  static const Color primaryLight = Color(0xFF2A9D8F);
  static const Color primaryDark = Color(0xFF0F3B45);
  static const Color primaryTint = Color(0xFFEBF5F7);

  // Background and Surfaces
  static const Color background = Color(0xFFF3F6F8);
  static const Color surface = Colors.white;
  static const Color surfaceSubtle = Color(0xFFF8FAFC);
  static const Color border = Color(0xFFE2E8F0);

  // Status colors
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFE6F9F3);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFEFF6FF);

  // Typography colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);

  // Card Decoration
  static BoxDecoration cardDecoration({
    Color? borderColor,
    Color? bgColor,
    double radius = 16,
  }) {
    return BoxDecoration(
      color: bgColor ?? surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor ?? border, width: 1.2),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
