import 'package:flutter/material.dart';

import 'package:changa_app/core/theme/app_colors.dart';
import 'package:changa_app/core/theme/app_spacing.dart';
import 'package:changa_app/core/theme/app_text_styles.dart';
import 'package:changa_app/core/widgets/progress_ring.dart';
import 'package:changa_app/features/dashboard/domain/entities/harmony_score.dart';
import 'package:changa_app/features/dashboard/presentation/cubit/dashboard_cubit.dart';

class HarmonyCard extends StatelessWidget {
  const HarmonyCard({
    super.key,
    required this.status,
    required this.score,
    required this.onInfo,
  });

  final DashboardSection status;
  final HarmonyScore? score;
  final VoidCallback onInfo;

  static String encouragement(HarmonyScore? score) {
    if (score == null) {
      return 'Add a chore or an expense and your score will appear.';
    }
    return switch (score.tier) {
      HarmonyTier.thriving => 'Your home is running smoothly. Keep it up!',
      HarmonyTier.steady => 'Doing well. A few more tasks on time will help.',
      HarmonyTier.needsAttention => "Let's get things back on track together.",
    };
  }

  @override
  Widget build(BuildContext context) {
    final ready = status == DashboardSection.ready;
    final headline = switch (status) {
      DashboardSection.loading => 'Loading...',
      DashboardSection.failed => "Couldn't load the score",
      DashboardSection.ready => score?.tier.label ?? 'Not enough data yet',
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.sherwoodGreen,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          ProgressRing(
            value: ready ? score?.value : null,
            size: 88,
            strokeWidth: 9,
            color: AppColors.lightGreen,
            trackColor: AppColors.ginFizz.withValues(alpha: 0.2),
            labelColor: AppColors.ginFizz,
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Harmony Score',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.ginFizz.withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  headline,
                  key: const Key('harmony-headline'),
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.ginFizz,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  ready ? encouragement(score) : '',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.ginFizz.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                InkWell(
                  key: const Key('harmony-info'),
                  onTap: onInfo,
                  borderRadius: BorderRadius.circular(8),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xs,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        widthFactor: 1,
                        heightFactor: 1,
                        child: Text(
                          "What's this? →",
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.lightGreen,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
