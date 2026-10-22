import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';

/// Top circular back navigation button matching Figma.
class AuthBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String? fallbackLocation;

  const AuthBackButton({super.key, this.onPressed, this.fallbackLocation});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            if (onPressed != null) {
              onPressed!();
            } else if (context.canPop()) {
              context.pop();
            } else {
              context.go(fallbackLocation ?? '/onboarding');
            }
          },
          child: const Center(
            child: Icon(
              Icons.arrow_back_rounded,
              size: 20,
              color: AppColors.sherwoodGreen,
            ),
          ),
        ),
      ),
    );
  }
}
