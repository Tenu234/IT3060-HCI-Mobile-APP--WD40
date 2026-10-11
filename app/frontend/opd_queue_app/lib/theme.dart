import 'package:flutter/material.dart';

class C {
  static const brand = Color(0xFF1865F2);
  static const bg = Color(0xFFF3F6FB);
  static const ink = Color(0xFF14233C);
  static const muted = Color(0xFF5B6B82);
  static const border = Color(0xFFD5E3F5);
  static const blueSoft = Color(0xFFE8F0FE);
  static const green = Color(0xFF1B7F3B);
  static const greenSoft = Color(0xFFE8F5E9);
  static const red = Color(0xFFC62828);
  static const redSoft = Color(0xFFFDECEA);
  static const amber = Color(0xFF9A6700);
  static const yellowSoft = Color(0xFFFFF9C4);
  static const grey = Color(0xFF6B7280);
  static const greySoft = Color(0xFFEEF0F3);
}

ThemeData buildTheme() {
  final base = ColorScheme.fromSeed(seedColor: C.brand, primary: C.brand);
  OutlineInputBorder border(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c, width: 1.2),
      );
  return ThemeData(
    useMaterial3: true,
    colorScheme: base,
    scaffoldBackgroundColor: C.bg,
    textTheme: ThemeData.light().textTheme.apply(bodyColor: C.ink, displayColor: C.ink),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: const TextStyle(color: C.muted),
      enabledBorder: border(C.border),
      focusedBorder: border(C.brand),
      errorBorder: border(C.red),
      focusedErrorBorder: border(C.red),
      disabledBorder: border(C.border),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: C.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
  );
}
