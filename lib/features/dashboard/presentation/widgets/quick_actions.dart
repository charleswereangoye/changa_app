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
    final labelStyle = AppTextStyles.label.copyWith(fontSize: 14);
    final textScaler = MediaQuery.textScalerOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        var requiredButtonWidth = 0.0;

        for (final label in ['Add Expense', 'Log Chore']) {
          final painter = TextPainter(
            text: TextSpan(text: label, style: labelStyle),
            textDirection: Directionality.of(context),
            textScaler: textScaler,
            locale: Localizations.maybeLocaleOf(context),
          )..layout();

          // Label, icon, icon gap, and horizontal padding.
          final width =
              painter.width.ceilToDouble() + 20 + AppSpacing.sm + 24 + 2;
          if (width > requiredButtonWidth) {
            requiredButtonWidth = width;
          }

          painter.dispose();
        }

        final availableButtonWidth = (constraints.maxWidth - AppSpacing.md) / 2;
        final stackButtons = availableButtonWidth < requiredButtonWidth;

        final expense = _Action(
          key: const Key('quick-add-expense'),
          icon: Icons.add,
          label: 'Add Expense',
          filled: true,
          onTap: onAddExpense,
        );

        final chore = _Action(
          key: const Key('quick-add-chore'),
          icon: Icons.check,
          label: 'Log Chore',
          filled: false,
          onTap: onAddChore,
        );

        if (stackButtons) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              expense,
              const SizedBox(height: AppSpacing.md),
              chore,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: expense),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: chore),
          ],
        );
      },
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

    return Semantics(
      button: true,
      child: Material(
        color: filled ? AppColors.sherwoodGreen : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: filled ? null : Border.all(color: AppColors.opal),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: foreground),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.label.copyWith(
                      color: foreground,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
