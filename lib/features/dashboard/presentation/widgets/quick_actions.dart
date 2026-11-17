import 'package:flutter/material.dart';

import 'package:changa_app/core/theme/app_colors.dart';
import 'package:changa_app/core/theme/app_spacing.dart';
import 'package:changa_app/core/theme/app_text_styles.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({
    super.key,
    required this.onAddExpense,
    required this.onSettleUp,
    required this.onAddChore,
  });

  final VoidCallback onAddExpense;
  final VoidCallback onSettleUp;
  final VoidCallback onAddChore;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Action(
            key: const Key('quick-add-expense'),
            icon: Icons.receipt_long_outlined,
            label: 'Add expense',
            onTap: onAddExpense,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _Action(
            key: const Key('quick-settle-up'),
            icon: Icons.handshake_outlined,
            label: 'Settle up',
            onTap: onSettleUp,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _Action(
            key: const Key('quick-add-chore'),
            icon: Icons.cleaning_services_outlined,
            label: 'Add chore',
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
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.lg,
            horizontal: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.opal),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.sherwoodGreen),
              const SizedBox(height: AppSpacing.sm),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTextStyles.label.copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
