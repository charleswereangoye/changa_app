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

  @override
  Widget build(BuildContext context) {
    final ready = status == DashboardSection.ready;
    final headline = switch (status) {
      DashboardSection.loading => 'Loading...',
      DashboardSection.failed => "Couldn't load the score",
      DashboardSection.ready => score?.tier.label ?? 'Not enough data yet',
    };
    final detail = ready && score == null
        ? 'Add a chore or an expense and your score will appear.'
        : 'Based on chores done on time and bills settled promptly.';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Household Harmony',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.ginFizz.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    IconButton(
                      key: const Key('harmony-info'),
                      onPressed: onInfo,
                      tooltip: 'How is this calculated?',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(
                        Icons.info_outline,
                        color: AppColors.ginFizz,
                        size: 20,
                      ),
                    ),
                  ],
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
                  detail,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.ginFizz.withValues(alpha: 0.8),
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
