import 'package:flutter/material.dart';

/// Monochrome color palette matching the sketch aesthetic.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF2D2D2D); // Main active color
  static const Color background = Color(0xFFF5F2ED); // Off-white / paper
  static const Color cardBackground = Color(0xFFFFFFFF); // White cards
  static const Color textPrimary = Color(0xFF2D2D2D); // Dark grey text
  static const Color textSecondary = Color(0xFF6B6B6B); // Medium grey
  static const Color textTertiary = Color(0xFF9E9E9E); // Light grey text
  static const Color border = Color(0xFFD9D9D9); // Light grey borders
  static const Color divider = Color(0xFFE8E8E8); // Divider color
  static const Color connectedGreen = Color(0xFF4CAF50); // Status green dot
  static const Color inputBackground = Color(0xFFF0EDE8); // Input field bg
  static const Color cardShadow = Color(0x1A000000); // Minimal shadow
}

/// App-wide theme configuration using Material 3.
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.textPrimary,
        brightness: Brightness.light,
        surface: AppColors.background,
        onSurface: AppColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
      textTheme: const TextTheme(
        // "Matt" splash title - large italic serif
        displayLarge: TextStyle(
          fontFamily: 'Serif',
          fontSize: 48,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
          letterSpacing: 1.0,
        ),
        // Section titles - "AI Personality", "Settings"
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
          letterSpacing: 0.5,
        ),
        // Card titles - "Coding Partner"
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        // Subtitle text - "Connect to your Local AI"
        headlineSmall: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
        // "Matt" in chat app bar
        titleLarge: TextStyle(
          fontFamily: 'Serif',
          fontSize: 22,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
        // Row titles, labels
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
        // Small labels, timestamps
        titleSmall: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
        // Body text - chat messages, descriptions
        bodyLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
          height: 1.4,
        ),
        // Secondary body text
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
          height: 1.4,
        ),
        // Small captions
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.textTertiary,
        ),
        // "Local AI" subtitle on splash
        labelLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
          letterSpacing: 2.0,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBackground,
        elevation: 2,
        shadowColor: AppColors.cardShadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.cardBackground,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
