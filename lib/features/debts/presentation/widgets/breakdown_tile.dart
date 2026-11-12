import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../expenses/domain/entities/expense.dart';
import '../../../expenses/domain/entities/expense_category.dart';
import '../../domain/entities/debt.dart';

class BreakdownTile extends StatelessWidget {
  const BreakdownTile({
    super.key,
    required this.debt,
    required this.meUid,
    this.expense,
    this.onTap,
  });

  final Debt debt;
  final String meUid;
  final Expense? expense;
  final VoidCallback? onTap;

  static IconData _categoryIcon(ExpenseCategory? category) {
    return switch (category) {
      ExpenseCategory.rent => Icons.home_outlined,
      ExpenseCategory.utilities => Icons.bolt_outlined,
      ExpenseCategory.internet => Icons.wifi_outlined,
      ExpenseCategory.water => Icons.water_drop_outlined,
      ExpenseCategory.cashpower => Icons.electric_bolt_outlined,
      ExpenseCategory.gas => Icons.local_fire_department_outlined,
      ExpenseCategory.groceries => Icons.shopping_cart_outlined,
      ExpenseCategory.other || null => Icons.receipt_long_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final item = expense;
    final isOwedToMe = debt.creditorUid == meUid;

    final date = DateFormat('MMM d, yyyy')
        .format((item?.createdAt ?? debt.createdAt).toLocal());

    // An unavailable expense cannot open its details.
    final handleTap = item == null ? null : onTap;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: handleTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _categoryIcon(item?.category),
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item?.title ?? 'Shared expense',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          item == null
                              ? '$date · Expense details unavailable'
                              : '$date · Total '
                                    '${CurrencyFormatter.format(item.totalAmount)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (handleTap != null) ...[
                    const SizedBox(width: AppSpacing.xs),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: colors.onSurfaceVariant,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      isOwedToMe ? 'They owe you' : 'You owe',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      CurrencyFormatter.format(debt.amount),
                      textAlign: TextAlign.end,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isOwedToMe
                            ? AppColors.leafGreen
                            : colors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              if (debt.creditsApplied > 0) ...[
                const SizedBox(height: AppSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.stars_outlined,
                      size: 18,
                      color: AppColors.leafGreen,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Chore credits applied · '
                        '${debt.creditsApplied} pts',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.leafGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
