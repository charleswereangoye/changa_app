import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Single slide showing illustration card, title, and description.
class OnboardingSlide extends StatelessWidget {
  final Widget illustration;
  final String title;
  final String description;

  const OnboardingSlide({
    super.key,
    required this.illustration,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Adjust card height dynamically based on available height
          final cardHeight = (constraints.maxHeight * 0.58).clamp(180.0, 280.0);

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Illustration card matching Figma
                Container(
                  width: double.infinity,
                  height: cardHeight,
                  decoration: BoxDecoration(
                    color: AppColors.athsSpecial,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: illustration,
                ),
                const SizedBox(height: 24),

                // Slide Title
                Text(
                  title,
                  style: AppTextStyles.heading2.copyWith(
                    color: AppColors.sherwoodGreen,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 12),

                // Slide Subtitle / Description
                Text(
                  description,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.sherwoodGreen.withValues(alpha: 0.85),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
