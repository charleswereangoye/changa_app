// Owner: C - Person C (Expenses, Dashboard, Documentation)
// Description: Widget tests for the Expense Details sheet

import 'package:changa_app/features/expenses/domain/usecases/delete_expense.dart';
import 'package:changa_app/features/expenses/domain/usecases/update_expense_note.dart';
import 'package:changa_app/features/expenses/presentation/cubit/expense_detail_cubit.dart';
import 'package:changa_app/features/expenses/presentation/widgets/expense_detail_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'expense_detail_cubit_test.dart';

Future<void> _open(
  WidgetTester tester,
  FakeDetailRepository repo, {
  String currentUid = 'amara',
}) async {
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final cubit = ExpenseDetailCubit(
    updateExpenseNote: UpdateExpenseNote(repo),
    deleteExpense: DeleteExpense(repo),
    householdId: 'h1',
    expense: sample(),
    currentUid: currentUid,
  );
  addTearDown(cubit.close);

  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => BlocProvider.value(
                    value: cubit,
                    child: const Scaffold(
                      body: ExpenseDetailSheet(payerName: 'Amara'),
                    ),
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the expense details', (tester) async {
    await _open(tester, FakeDetailRepository());

    expect(find.text('Groceries'), findsWidgets);
    expect(find.text('RWF 12,000'), findsOneWidget);
    expect(find.text('You'), findsOneWidget);
    expect(find.text('Split equally'), findsOneWidget);
    expect(find.text('No note yet.'), findsOneWidget);
  });

  testWidgets('someone who did not pay sees no edit or delete', (tester) async {
    await _open(tester, FakeDetailRepository(), currentUid: 'chloe');

    expect(find.byKey(const Key('detail-readonly')), findsOneWidget);
    expect(find.byKey(const Key('detail-edit')), findsNothing);
    expect(find.byKey(const Key('detail-delete')), findsNothing);
    expect(find.text('Amara'), findsOneWidget);
  });

  testWidgets('the payer can edit the title and save', (tester) async {
    final repo = FakeDetailRepository();
    await _open(tester, repo);

    await tester.tap(find.byKey(const Key('detail-edit')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('detail-title-field')),
      'Weekly groceries',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('detail-save')));
    await tester.pumpAndSettle();

    expect(repo.updateCalls, 1);
    expect(repo.lastTitle, 'Weekly groceries');
    expect(find.text('Weekly groceries'), findsOneWidget);
  });

  testWidgets('Save is disabled until something changes', (tester) async {
    await _open(tester, FakeDetailRepository());

    await tester.tap(find.byKey(const Key('detail-edit')));
    await tester.pumpAndSettle();

    final save = tester.widget<ElevatedButton>(
      find.descendant(
        of: find.byKey(const Key('detail-save')),
        matching: find.byType(ElevatedButton),
      ),
    );
    expect(save.onPressed, isNull);
  });

  testWidgets('delete asks first, then deletes and closes', (tester) async {
    final repo = FakeDetailRepository();
    await _open(tester, repo);

    await tester.tap(find.byKey(const Key('detail-delete')));
    await tester.pumpAndSettle();
    expect(find.text('Delete this expense?'), findsOneWidget);
    expect(repo.deleteCalls, 0);

    await tester.tap(find.byKey(const Key('detail-confirm-delete')));
    await tester.pumpAndSettle();

    expect(repo.deleteCalls, 1);
    expect(find.byType(ExpenseDetailSheet), findsNothing);
  });

  testWidgets('cancelling the delete dialog keeps the expense', (tester) async {
    final repo = FakeDetailRepository();
    await _open(tester, repo);

    await tester.tap(find.byKey(const Key('detail-delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('detail-cancel-delete')));
    await tester.pumpAndSettle();

    expect(repo.deleteCalls, 0);
    expect(find.byType(ExpenseDetailSheet), findsOneWidget);
  });
}
