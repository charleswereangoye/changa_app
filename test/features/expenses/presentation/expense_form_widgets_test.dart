// Owner: C - Person C (Expenses, Dashboard, Documentation)
// Description: Widget tests for the Add Expense form building blocks

import 'package:changa_app/features/expenses/domain/entities/expense_category.dart';
import 'package:changa_app/features/expenses/domain/entities/split_type.dart';
import 'package:changa_app/features/expenses/presentation/widgets/category_chips.dart';
import 'package:changa_app/features/expenses/presentation/widgets/split_type_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('tapping a category chip reports that category', (tester) async {
    ExpenseCategory? picked;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CategoryChips(
            selected: ExpenseCategory.groceries,
            onSelected: (c) => picked = c,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Rent'));
    await tester.pump();

    expect(picked, ExpenseCategory.rent);
  });

  testWidgets('tapping Percent reports the percent split type', (tester) async {
    SplitType? picked;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SplitTypeSelector(
            selected: SplitType.equal,
            onChanged: (t) => picked = t,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Percent'));
    await tester.pump();

    expect(picked, SplitType.percent);
  });
}
