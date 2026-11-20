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
            return AppColors.white;
          }
          return AppColors.edward;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.lightGreen;
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
}
