import 'package:flutter/material.dart';

import 'package:changa_app/core/constants/app_constants.dart';
import 'package:changa_app/core/theme/app_colors.dart';
import 'package:changa_app/core/theme/app_spacing.dart';
import 'package:changa_app/core/theme/app_text_styles.dart';
import 'package:changa_app/core/widgets/primary_button.dart';

class HarmonyExplainerSheet extends StatelessWidget {
  const HarmonyExplainerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.ginFizz,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const HarmonyExplainerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Harmony & Credits',
                        style: AppTextStyles.heading2,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'How your household score works',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.sherwoodGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: const Key('harmony-close'),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Close',
                  icon: const Icon(Icons.close, color: AppColors.sherwoodGreen),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            _InfoCard(
              icon: Icons.favorite,
              iconColor: AppColors.sunglo,
              title: 'Harmony Score',
              body:
                  'A score from 0 to 100 for the whole household, never one '
                  'person. Half comes from chores finished on time over the '
                  'last ${AppConstants.harmonyChoreWindowDays} days, half from '
                  'bills settled within '
                  '${AppConstants.harmonySettleWindowDays} days.',
              footer: [
                _Tier(
                  label: 'Thriving',
                  range: '${AppConstants.harmonyThrivingMin} and above',
                ),
                _Tier(
                  label: 'Steady',
                  range:
                      '${AppConstants.harmonySteadyMin} to '
                      '${AppConstants.harmonyThrivingMin - 1}',
                ),
                _Tier(
                  label: 'Needs attention',
                  range: 'Below ${AppConstants.harmonySteadyMin}',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _InfoCard(
              icon: Icons.star,
              iconColor: AppColors.goldSand,
              title: 'Credits',
              body:
                  'Finish a chore to earn credits: easy '
                  '${AppConstants.creditsEasy}, medium '
                  '${AppConstants.creditsMedium}, hard '
                  '${AppConstants.creditsHard}. Credits are used automatically '
                  'to cover what you owe. 1 credit = RWF 10.',
            ),
            const SizedBox(height: AppSpacing.xl),
            const Text('Tips to improve', style: AppTextStyles.bodyLarge),
            const SizedBox(height: AppSpacing.sm),
            const _Tip('Finish chores on or before their due day'),
            const _Tip('Settle up within a few days of a new bill'),
            const _Tip('Swap a chore early if you cannot do it'),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              key: const Key('harmony-got-it'),
              text: 'Got it',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    this.footer = const [],
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final List<Widget> footer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(title, style: AppTextStyles.bodyLarge),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(body, style: AppTextStyles.bodyMedium),
          if (footer.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            ...footer,
          ],
        ],
      ),
    );
  }
}

class _Tier extends StatelessWidget {
  const _Tier({required this.label, required this.range});

  final String label;
  final String range;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.label)),
          Text(range, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  const _Tip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 20, color: AppColors.leafGreen),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }
}
