import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Main theme definition for Changa.
class AppTheme {
  AppTheme._();

  /// Light theme matching Figma colors and typography.
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Poppins',
      scaffoldBackgroundColor: AppColors.ginFizz,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.sherwoodGreen,
        onPrimary: AppColors.ginFizz,
        // Credit badge pill.
        primaryContainer: AppColors.athsSpecial,
        onPrimaryContainer: AppColors.sherwoodGreen,
        secondary: AppColors.sunglo,
        onSecondary: AppColors.white,
        // Harmony "Steady" ring. Kept apart from error so tiers never match.
        tertiary: AppColors.goldSand,
        onTertiary: AppColors.sherwoodGreen,
        error: AppColors.sunglo,
        onError: AppColors.white,
        surface: AppColors.ginFizz,
        onSurface: AppColors.sherwoodGreen,
        // Empty ring track and the "no score yet" outline.
        outline: AppColors.edward,
        outlineVariant: AppColors.inactiveDot,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.ginFizz,
        foregroundColor: AppColors.sherwoodGreen,
        elevation: 0,
        centerTitle: true,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.sherwoodGreen;
            }
            return AppColors.white;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.ginFizz;
            }
            return AppColors.sherwoodGreen;
          }),
          side: const WidgetStatePropertyAll(
            BorderSide(color: AppColors.sherwoodGreen),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.lightGreen;
          }
          return AppColors.edward;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.sherwoodGreen;
          }
          return AppColors.edward.withValues(alpha: 0.3);
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.white,
        selectedColor: AppColors.sherwoodGreen,
        side: const BorderSide(color: AppColors.sherwoodGreen),
        labelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          color: AppColors.sherwoodGreen,
        ),
        secondaryLabelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          color: AppColors.ginFizz,
        ),
      ),
    );
  }

  /// Dark theme matching Changa dark green brand aesthetic.
  static ThemeData get darkTheme {
    const darkBg = Color(0xFF041E1C);
    const darkSurface = Color(0xFF072B28);
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Poppins',
      scaffoldBackgroundColor: darkBg,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.lightGreen,
        onPrimary: AppColors.sherwoodGreen,
        primaryContainer: Color(0xFF083833),
        onPrimaryContainer: AppColors.lightGreen,
        secondary: AppColors.sunglo,
        onSecondary: AppColors.white,
        tertiary: AppColors.goldSand,
        onTertiary: AppColors.sherwoodGreen,
        error: AppColors.sunglo,
        onError: AppColors.white,
        surface: darkSurface,
        onSurface: AppColors.ginFizz,
        outline: AppColors.pewter,
        outlineVariant: AppColors.edward,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBg,
        foregroundColor: AppColors.ginFizz,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.lightGreen;
            }
            return darkSurface;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.sherwoodGreen;
            }
            return AppColors.ginFizz;
          }),
          side: const WidgetStatePropertyAll(
            BorderSide(color: AppColors.lightGreen),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.sherwoodGreen;
          }
          return AppColors.pewter;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.lightGreen;
          }
          return const Color(0xFF0F3E3A);
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkSurface,
        selectedColor: AppColors.lightGreen,
        side: const BorderSide(color: AppColors.lightGreen),
        labelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          color: AppColors.ginFizz,
        ),
        secondaryLabelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          color: AppColors.sherwoodGreen,
        ),
      ),
    );
  }
}
