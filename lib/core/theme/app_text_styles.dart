import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Typography styles matching Figma specifications.
class AppTextStyles {
  // Prevent creating instances of this class.
  AppTextStyles._();

  // Headings
  static const TextStyle heading1 = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.sherwoodGreen,
  );

  static const TextStyle heading2 = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.sherwoodGreen,
  );

  // Body text
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.sherwoodGreen,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.sherwoodGreen,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.edward,
  );

  // Buttons and labels
  static const TextStyle button = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
  );

  static const TextStyle label = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.sherwoodGreen,
  );
}
