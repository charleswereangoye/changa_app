import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Clean social sign-in button (Google / Apple) matching Figma.
class SocialAuthButton extends StatelessWidget {
  final String label;
  final Widget? icon;
  final VoidCallback? onPressed;

  const SocialAuthButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.white,
          elevation: 0,
          side: BorderSide(
            color: AppColors.sherwoodGreen.withValues(alpha: 0.1),
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[icon!, const SizedBox(width: 8)],
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.sherwoodGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
