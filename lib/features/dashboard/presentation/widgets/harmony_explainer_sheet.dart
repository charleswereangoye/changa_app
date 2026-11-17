import 'package:flutter/material.dart';

import 'package:changa_app/core/constants/app_constants.dart';
import 'package:changa_app/core/theme/app_colors.dart';
import 'package:changa_app/core/theme/app_spacing.dart';
import 'package:changa_app/core/theme/app_text_styles.dart';

class HarmonyExplainerSheet extends StatelessWidget {
  const HarmonyExplainerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppColors.white,
      builder: (_) => const HarmonyExplainerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        0,
        AppSpacing.xxl,
        AppSpacing.xxl,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('How Harmony works', style: AppTextStyles.heading2),
            const SizedBox(height: AppSpacing.md),
            Text(
              'The score is about the whole household, never one person. '
              'It goes from 0 to 100 and is made of two halves:',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            _Point(
              title: 'Chores (half of the score)',
              body:
                  'Chores finished on or before their due day, over the last '
                  '${AppConstants.harmonyChoreWindowDays} days.',
            ),
            _Point(
              title: 'Payments (half of the score)',
              body:
                  'Bills settled within ${AppConstants.harmonySettleWindowDays} '
                  'days, over the last ${AppConstants.harmonyDebtWindowDays} '
                  'days. Bills covered by credits count as on time.',
            ),
            const SizedBox(height: AppSpacing.md),
            const Text('What the numbers mean', style: AppTextStyles.bodyLarge),
            const SizedBox(height: AppSpacing.xs),
            _Point(
              title: 'Thriving',
              body: '${AppConstants.harmonyThrivingMin} and above',
            ),
            _Point(
              title: 'Steady',
              body:
                  '${AppConstants.harmonySteadyMin} to '
                  '${AppConstants.harmonyThrivingMin - 1}',
            ),
            _Point(
              title: 'Needs attention',
              body: 'Below ${AppConstants.harmonySteadyMin}',
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'If there is no data yet, you will see a dash instead of a '
              'number.',
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.label),
          Text(body, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}
