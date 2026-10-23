// Owner: C - Person C (Expenses, Dashboard, Documentation)
// Description: Expense category selection chips

import 'package:flutter/material.dart';

import 'package:changa_app/core/theme/app_colors.dart';
import 'package:changa_app/core/theme/app_spacing.dart';
import 'package:changa_app/core/theme/app_text_styles.dart';
import 'package:changa_app/features/expenses/domain/entities/expense_category.dart';

class CategoryChips extends StatelessWidget {
  const CategoryChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final ExpenseCategory selected;
  final ValueChanged<ExpenseCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final category in ExpenseCategory.values) _chip(category),
      ],
    );
  }

  Widget _chip(ExpenseCategory category) {
    final isSelected = category == selected;
    final foreground = isSelected ? AppColors.ginFizz : AppColors.sherwoodGreen;
    return ChoiceChip(
      avatar: Icon(_icon(category), size: 18, color: foreground),
      label: Text(_label(category)),
      labelStyle: AppTextStyles.label.copyWith(color: foreground),
      selected: isSelected,
      showCheckmark: false,
      selectedColor: AppColors.sherwoodGreen,
      backgroundColor: AppColors.white,
      side: BorderSide(
        color: isSelected ? AppColors.sherwoodGreen : AppColors.edward,
      ),
      shape: const StadiumBorder(),
      onSelected: (_) => onSelected(category),
    );
  }

  static String _label(ExpenseCategory category) => switch (category) {
    ExpenseCategory.rent => 'Rent',
    ExpenseCategory.utilities => 'Utilities',
    ExpenseCategory.internet => 'Internet',
    ExpenseCategory.water => 'Water',
    ExpenseCategory.cashpower => 'Cashpower',
    ExpenseCategory.gas => 'Gas',
    ExpenseCategory.groceries => 'Groceries',
    ExpenseCategory.other => 'Other',
  };

  static IconData _icon(ExpenseCategory category) => switch (category) {
    ExpenseCategory.rent => Icons.home_outlined,
    ExpenseCategory.utilities => Icons.receipt_long_outlined,
    ExpenseCategory.internet => Icons.wifi,
    ExpenseCategory.water => Icons.water_drop_outlined,
    ExpenseCategory.cashpower => Icons.bolt,
    ExpenseCategory.gas => Icons.local_fire_department_outlined,
    ExpenseCategory.groceries => Icons.shopping_cart_outlined,
    ExpenseCategory.other => Icons.more_horiz,
  };
}
