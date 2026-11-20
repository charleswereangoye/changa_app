import 'package:flutter/material.dart';

import 'package:changa_app/core/theme/app_colors.dart';
import 'package:changa_app/core/theme/app_spacing.dart';
import 'package:changa_app/core/theme/app_text_styles.dart';
import 'package:changa_app/core/widgets/member_avatar.dart';
import 'package:changa_app/core/widgets/money_text.dart';
import 'package:changa_app/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:changa_app/features/debts/domain/entities/balance_summary.dart';

class BalanceSummaryCard extends StatelessWidget {
  const BalanceSummaryCard({
    super.key,
    required this.status,
    required this.summary,
    required this.names,
    required this.onRetry,
    this.onMemberTap,
    this.onSettleUp,
  });

  final DashboardSection status;
  final BalanceSummary? summary;
  final Map<String, String> names;
  final VoidCallback onRetry;
  final ValueChanged<String>? onMemberTap;
  final VoidCallback? onSettleUp;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.athsSpecial),
      ),
      child: switch (status) {
        DashboardSection.loading => const SizedBox(
          height: 96,
          child: Center(child: CircularProgressIndicator()),
        ),
        DashboardSection.failed => Column(
          children: [
            const Text(
              "Couldn't load your balances.",
              style: AppTextStyles.bodyMedium,
            ),
            TextButton(
              key: const Key('balance-retry'),
              onPressed: onRetry,
              child: const Text('Try again'),
            ),
          ],
        ),
        DashboardSection.ready => _Loaded(
          summary: summary,
          names: names,
          onMemberTap: onMemberTap,
          onSettleUp: onSettleUp,
        ),
      },
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({
    required this.summary,
    required this.names,
    required this.onMemberTap,
    required this.onSettleUp,
  });

  final BalanceSummary? summary;
  final Map<String, String> names;
  final ValueChanged<String>? onMemberTap;
  final VoidCallback? onSettleUp;

  @override
  Widget build(BuildContext context) {
    final data = summary;
    final entries =
        (data?.byMember.entries.where((entry) => entry.value != 0).toList() ??
              <MapEntry<String, int>>[])
          ..sort((a, b) => b.value.abs().compareTo(a.value.abs()));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _Total(
                label: 'You are owed',
                amount: data?.youAreOwed ?? 0,
                color: AppColors.sherwoodGreen,
              ),
            ),
            Expanded(
              child: _Total(
                label: 'You owe',
                amount: data?.youOwe ?? 0,
                color: AppColors.lightGreen,
              ),
            ),
            if (onSettleUp != null)
              FilledButton(
                key: const Key('balance-settle-up'),
                onPressed: onSettleUp,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.athsSpecial,
                  foregroundColor: AppColors.sherwoodGreen,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  textStyle: AppTextStyles.label,
                ),
                child: const Text('Settle Up'),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (entries.isEmpty)
          Container(
            key: const Key('balance-settled'),
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.ginFizz,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: AppColors.leafGreen,
                  size: 22,
                ),
                const SizedBox(width: AppSpacing.sm),
                const Text('All settled up', style: AppTextStyles.label),
              ],
            ),
          )
        else
          for (final entry in entries)
            InkWell(
              key: Key('balance-row-${entry.key}'),
              onTap: onMemberTap == null ? null : () => onMemberTap!(entry.key),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    MemberAvatar(
                      uid: entry.key,
                      name: names[entry.key] ?? 'Housemate',
                      radius: 16,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        names[entry.key] ?? 'Housemate',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        MoneyText(
                          entry.value.abs(),
                          style: AppTextStyles.label.copyWith(
                            color: entry.value > 0
                                ? AppColors.sherwoodGreen
                                : AppColors.lightGreen,
                          ),
                        ),
                        Text(
                          entry.value > 0 ? 'owes you' : 'to pay back',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}

class _Total extends StatelessWidget {
  const _Total({
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final int amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.bodySmall),
        const SizedBox(height: AppSpacing.xs),
        MoneyText(
          amount,
          style: AppTextStyles.heading2.copyWith(color: color, fontSize: 20),
        ),
      ],
    );
  }
}
