import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/balance_summary.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({super.key, required this.summary, this.onSettleUp});

  final BalanceSummary summary;
  final VoidCallback? onSettleUp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final allSettled = summary.youAreOwed == 0 && summary.youOwe == 0;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: allSettled
            ? Row(
                children: [
                  CircleAvatar(
                    backgroundColor: colors.primaryContainer,
                    foregroundColor: colors.onPrimaryContainer,
                    child: const Icon(Icons.check_rounded),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'All settled up',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'You owe RWF 0 · You’re owed RWF 0',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _BalanceAmount(
                          label: 'You are owed',
                          amount: summary.youAreOwed,
                          color: AppColors.leafGreen,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: _BalanceAmount(
                          label: 'You owe',
                          amount: summary.youOwe,
                          color: colors.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Divider(color: colors.outlineVariant),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.lg,
                    runSpacing: AppSpacing.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Net balance: '
                        '${summary.net > 0 ? '+' : ''}'
                        '${CurrencyFormatter.format(summary.net)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (onSettleUp != null)
                        FilledButton.tonal(
                          onPressed: onSettleUp,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 48),
                          ),
                          child: const Text('Settle Up'),
                        ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

class _BalanceAmount extends StatelessWidget {
  const _BalanceAmount({
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final int amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          CurrencyFormatter.format(amount),
          style: theme.textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
