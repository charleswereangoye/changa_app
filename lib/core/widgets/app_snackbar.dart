import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Custom SnackBar utility delivering polite, styled in-app feedback.
class AppSnackbar {
  AppSnackbar._();

  /// Displays an error alert message (coral background).
  static void error(BuildContext context, String message) {
    _show(
      context: context,
      message: message,
      backgroundColor: AppColors.sunglo,
      icon: Icons.error_outline_rounded,
    );
  }

  /// Displays a success confirmation message (green background).
  static void success(BuildContext context, String message) {
    _show(
      context: context,
      message: message,
      backgroundColor: AppColors.leafGreen,
      icon: Icons.check_circle_outline_rounded,
    );
  }

  /// Displays an informative message (dark green background).
  static void info(BuildContext context, String message) {
    _show(
      context: context,
      message: message,
      backgroundColor: AppColors.sherwoodGreen,
      icon: Icons.info_outline_rounded,
    );
  }

  static void _show({
    required BuildContext context,
    required String message,
    required Color backgroundColor,
    required IconData icon,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          duration: const Duration(seconds: 4),
        ),
      );
  }
}
