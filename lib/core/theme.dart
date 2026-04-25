// lib/core/theme.dart
import 'package:flutter/material.dart';
import 'constants.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF020617),
      primaryColor: AppConstants.accentIndigo,
      colorScheme: const ColorScheme.dark(
        primary: AppConstants.accentIndigo,
        secondary: AppConstants.accentCyan,
        surface: Color(0xFF0F172A),
        surfaceContainer: Color(0xFF1E293B),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E293B),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Colors.white10),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC), // Ultra-clean white slate
      primaryColor: const Color(0xFF4F46E5), // Royal Indigo
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF4F46E5),
        secondary: Color(0xFF06B6D4), // Mint Cyan
        surface: Colors.white,
        surfaceContainer: Color(0xFFF1F5F9),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 15,
        shadowColor: const Color(0xFF4F46E5).withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFF1F5F9)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF0F172A)),
      ),
    );
  }
}
