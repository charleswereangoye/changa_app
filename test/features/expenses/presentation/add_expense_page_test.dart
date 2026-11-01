import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:changa_app/core/error/result.dart';
import 'package:changa_app/features/expenses/domain/entities/expense.dart';
import 'package:changa_app/features/expenses/domain/entities/split_type.dart';
import 'package:changa_app/features/expenses/domain/usecases/add_expense.dart';
import 'package:changa_app/features/expenses/presentation/cubit/add_expense_cubit.dart';
import 'package:changa_app/features/expenses/presentation/cubit/add_expense_state.dart';
import 'package:changa_app/features/expenses/presentation/pages/add_expense_page.dart';

import 'add_expense_cubit_test.dart' show FakeExpenseRepository;

void main() {
  late FakeExpenseRepository repo;
  late AddExpenseCubit cubit;

  setUp(() {
    repo = FakeExpenseRepository();
    cubit = AddExpenseCubit(
      addExpense: AddExpense(repo),
      householdId: 'house1',
      participants: const [
        ExpenseParticipant(uid: 'amara', name: 'Amara K'),
        ExpenseParticipant(uid: 'bob', name: 'Bob N'),
        ExpenseParticipant(uid: 'chloe', name: 'Chloe M'),
      ],
      currentUid: 'amara',
    );
  });

  tearDown(() => cubit.close());

  Future<void> pumpPage(WidgetTester tester) async {
    // A tall screen so nothing needs scrolling in the test.
    tester.view.physicalSize = const Size(900, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider.value(value: cubit, child: const AddExpensePage()),
        ),
      ),
    );
  }

  ElevatedButton saveButton(WidgetTester tester) =>
      tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Save expense'),
      );

  testWidgets('Save is disabled until the form is valid', (tester) async {
    await pumpPage(tester);
    expect(saveButton(tester).onPressed, isNull);

    await tester.enterText(find.byKey(const Key('amount-field')), '12000');
    await tester.enterText(find.byKey(const Key('title-field')), 'Groceries');
    await tester.pump();

    expect(saveButton(tester).onPressed, isNotNull);
    expect(
      find.text('Split equally among 3 people, RWF 4,000 each'),
      findsOneWidget,
    );
  });

  testWidgets('a percent total of 90 shows the error', (tester) async {
    await pumpPage(tester);
    await tester.enterText(find.byKey(const Key('amount-field')), '12000');
    await tester.enterText(find.byKey(const Key('title-field')), 'Groceries');

    await tester.tap(find.text('Percent'));
    await tester.pumpAndSettle();
    expect(cubit.state.splitType, SplitType.percent);

    await tester.enterText(
      find.byKey(const ValueKey('share-amara-percent')),
      '60',
    );
    await tester.enterText(
      find.byKey(const ValueKey('share-bob-percent')),
      '30',
    );
    await tester.pump();

    expect(find.text('Total: 90%'), findsOneWidget);
    expect(find.text('Percentages must add up to 100.'), findsOneWidget);
    expect(saveButton(tester).onPressed, isNull);

    await tester.enterText(
      find.byKey(const ValueKey('share-chloe-percent')),
      '10',
    );
    await tester.pump();

    expect(find.text('Total: 100%'), findsOneWidget);
    expect(saveButton(tester).onPressed, isNotNull);
  });

  testWidgets('the form is locked while the save is running', (tester) async {
    repo.gate = Completer<Result<Expense>>();
    await pumpPage(tester);
    await tester.enterText(find.byKey(const Key('amount-field')), '12000');
    await tester.enterText(find.byKey(const Key('title-field')), 'Groceries');
    await tester.pump();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Save expense'));
    await tester.pump();

    expect(cubit.state.status, AddExpenseStatus.submitting);
    expect(
      tester.widget<TextField>(find.byKey(const Key('amount-field'))).enabled,
      isFalse,
    );
    expect(
      tester.widget<TextField>(find.byKey(const Key('title-field'))).enabled,
      isFalse,
    );

    // Tapping an avatar while saving changes nothing.
    await tester.tap(find.byKey(const ValueKey('split-with-bob')));
    await tester.pump();
    expect(cubit.state.selectedUids, ['amara', 'bob', 'chloe']);
    expect(repo.addCalls, 1);
  });
}
