import 'package:flutter/material.dart';

import 'package:changa_app/core/theme/app_colors.dart';
import 'package:changa_app/core/theme/app_spacing.dart';
import 'package:changa_app/core/theme/app_text_styles.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({
    super.key,
    required this.onAddExpense,
    required this.onAddChore,
  });

  final VoidCallback onAddExpense;
  final VoidCallback onAddChore;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Action(
            key: const Key('quick-add-expense'),
            icon: Icons.add,
            label: 'Add Expense',
            filled: true,
            onTap: onAddExpense,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _Action(
            key: const Key('quick-add-chore'),
            icon: Icons.check,
            label: 'Log Chore',
            filled: false,
            onTap: onAddChore,
          ),
        ),
      ],
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    super.key,
    required this.icon,
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = filled ? AppColors.white : AppColors.sherwoodGreen;

    return Material(
      color: filled ? AppColors.sherwoodGreen : AppColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: filled ? null : Border.all(color: AppColors.opal),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: foreground),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: AppTextStyles.label.copyWith(
                  color: foreground,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
