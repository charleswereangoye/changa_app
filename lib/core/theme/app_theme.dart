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
        secondary: AppColors.sunglo,
        onSecondary: AppColors.white,
        error: AppColors.sunglo,
        onError: AppColors.white,
        surface: AppColors.ginFizz,
        onSurface: AppColors.sherwoodGreen,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.ginFizz,
        foregroundColor: AppColors.sherwoodGreen,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}
