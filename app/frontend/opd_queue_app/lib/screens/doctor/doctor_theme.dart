import 'package:flutter/material.dart';

class DoctorTheme {
  // Primary medical teal matching the system and reference aesthetic
  static const Color primary = Color(0xFF1A5C6B);
  static const Color primaryLight = Color(0xFF2E8B9A);
  static const Color primaryDark = Color(0xFF0E3842);
  static const Color primaryTint = Color(0xFFE6F3F5);

  // Background and Surfaces matching modern healthcare app screenshot
  static const Color background = Color(0xFFF6F9FA);
  static const Color surface = Colors.white;
  static const Color surfaceSubtle = Color(0xFFF1F5F8);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFEDF2F7);

  // Banner Gradient
  static const Color bannerStart = Color(0xFFDFF0F4);
  static const Color bannerEnd = Color(0xFFCCE7EE);

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

  // Modern Card Decoration
  static BoxDecoration cardDecoration({
    Color? borderColor,
    Color? bgColor,
    double radius = 18,
  }) {
    return BoxDecoration(
      color: bgColor ?? surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor ?? borderLight, width: 1.2),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.04),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
