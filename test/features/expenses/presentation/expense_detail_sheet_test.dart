// Owner: C - Person C (Expenses, Dashboard, Documentation)
// Description: Widget tests for the Expense Details sheet

import 'package:changa_app/core/enums/settlement_method.dart';
import 'package:changa_app/features/debts/domain/entities/debt_status.dart';
import 'package:changa_app/features/expenses/domain/usecases/delete_expense.dart';
import 'package:changa_app/features/expenses/domain/usecases/update_expense_note.dart';
import 'package:changa_app/features/expenses/domain/usecases/watch_expense_debts.dart';
import 'package:changa_app/features/expenses/presentation/cubit/expense_detail_cubit.dart';
import 'package:changa_app/features/expenses/presentation/widgets/expense_detail_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'expense_detail_cubit_test.dart';

const _names = {'amara': 'Amara', 'bob': 'Bob', 'chloe': 'Chloe'};

Future<void> _open(
  WidgetTester tester,
  FakeDetailRepository repo, {
  String currentUid = 'amara',
}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final cubit = ExpenseDetailCubit(
    updateExpenseNote: UpdateExpenseNote(repo),
    deleteExpense: DeleteExpense(repo),
    watchExpenseDebts: WatchExpenseDebts(repo),
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
                    child: Scaffold(
                      body: ExpenseDetailSheet(
                        currentUid: currentUid,
                        names: _names,
                      ),
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

String _statusOf(WidgetTester tester, String uid) =>
    tester.widget<Text>(find.byKey(Key('share-status-$uid'))).data!;

TextButton _deleteButton(WidgetTester tester) =>
    tester.widget<TextButton>(find.byKey(const Key('detail-delete')));

void main() {
  testWidgets('shows the expense details', (tester) async {
    await _open(tester, FakeDetailRepository());

    expect(find.text('Groceries'), findsWidgets);
    expect(find.text('RWF 12,000'), findsOneWidget);
    expect(find.text('Split equally'), findsOneWidget);
    expect(find.text('No note yet.'), findsOneWidget);
  });

  testWidgets('lists each person with their share and payment status', (
    tester,
  ) async {
    await _open(
      tester,
      FakeDetailRepository(
        debtsNow: [
          debt('bob', 600, credits: 340),
          debt(
            'chloe',
            4000,
            status: DebtStatus.settled,
            method: SettlementMethod.cash,
          ),
        ],
      ),
    );

    expect(find.text('Who pays what'), findsOneWidget);
    expect(_statusOf(tester, 'amara'), 'Paid the bill');
    expect(_statusOf(tester, 'bob'), 'Pending');
    expect(_statusOf(tester, 'chloe'), 'Paid with Cash');
    // Three shares of RWF 4,000, and Bob's credits are shown.
    expect(find.text('RWF 4,000'), findsNWidgets(3));
    expect(find.text('RWF 600 after 340 pts'), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);
    expect(find.text('Chloe'), findsOneWidget);
    expect(find.text('You'), findsNWidgets(2)); // "Paid by" and the share row
  });

  testWidgets('a debt covered by credits says so', (tester) async {
    await _open(
      tester,
      FakeDetailRepository(
        debtsNow: [
          debt(
            'bob',
            0,
            credits: 400,
            status: DebtStatus.settled,
            method: SettlementMethod.credits,
          ),
        ],
      ),
    );

    expect(_statusOf(tester, 'bob'), 'Covered by credits');
  });

  testWidgets('someone who did not pay sees no edit or delete', (tester) async {
    await _open(tester, FakeDetailRepository(), currentUid: 'chloe');

    expect(find.byKey(const Key('detail-readonly')), findsOneWidget);
    expect(find.byKey(const Key('detail-edit')), findsNothing);
    expect(find.byKey(const Key('detail-delete')), findsNothing);
    expect(find.text('Amara'), findsWidgets);
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

  group('delete', () {
    testWidgets('asks first, then deletes and closes', (tester) async {
      final repo = FakeDetailRepository(debtsNow: [debt('bob', 4000)]);
      await _open(tester, repo);

      expect(_deleteButton(tester).onPressed, isNotNull);
      await tester.tap(find.byKey(const Key('detail-delete')));
      await tester.pumpAndSettle();
      expect(find.text('Delete this expense?'), findsOneWidget);
      expect(repo.deleteCalls, 0);

      await tester.tap(find.byKey(const Key('detail-confirm-delete')));
      await tester.pumpAndSettle();

      expect(repo.deleteCalls, 1);
      expect(find.byType(ExpenseDetailSheet), findsNothing);
    });

    testWidgets('cancelling the dialog keeps the expense', (tester) async {
      final repo = FakeDetailRepository();
      await _open(tester, repo);

      await tester.tap(find.byKey(const Key('detail-delete')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('detail-cancel-delete')));
      await tester.pumpAndSettle();

      expect(repo.deleteCalls, 0);
      expect(find.byType(ExpenseDetailSheet), findsOneWidget);
    });

    testWidgets('is disabled with an explanation once a debt is paid', (
      tester,
    ) async {
      final repo = FakeDetailRepository(
        debtsNow: [
          debt(
            'bob',
            4000,
            status: DebtStatus.settled,
            method: SettlementMethod.cash,
          ),
          debt('chloe', 4000),
        ],
      );
      await _open(tester, repo);

      expect(_deleteButton(tester).onPressed, isNull);
      expect(find.byKey(const Key('detail-delete-blocked')), findsOneWidget);
      expect(
        find.text(
          'One housemate has already paid their share, so this expense can '
          'no longer be deleted.',
        ),
        findsOneWidget,
      );

      // Tapping the disabled button does nothing.
      await tester.tap(find.byKey(const Key('detail-delete')));
      await tester.pumpAndSettle();
      expect(find.text('Delete this expense?'), findsNothing);
      expect(repo.deleteCalls, 0);
    });

    testWidgets('a debt covered by credits does not disable it', (
      tester,
    ) async {
      await _open(
        tester,
        FakeDetailRepository(
          debtsNow: [
            debt(
              'bob',
              0,
              credits: 400,
              status: DebtStatus.settled,
              method: SettlementMethod.credits,
            ),
          ],
        ),
      );

      expect(_deleteButton(tester).onPressed, isNotNull);
      expect(find.byKey(const Key('detail-delete-blocked')), findsNothing);
    });

    testWidgets('is disabled while payments load', (tester) async {
      await _open(tester, FakeDetailRepository(debtsNeverLoad: true));

      expect(_deleteButton(tester).onPressed, isNull);
      expect(find.byKey(const Key('detail-delete-checking')), findsOneWidget);
      expect(find.byKey(const Key('shares-loading')), findsOneWidget);
    });

    testWidgets('switches off when a payment arrives while open', (
      tester,
    ) async {
      final repo = FakeDetailRepository(debtsNow: [debt('bob', 4000)]);
      await _open(tester, repo);
      expect(_deleteButton(tester).onPressed, isNotNull);

      repo.debtController.add([
        debt(
          'bob',
          4000,
          status: DebtStatus.settled,
          method: SettlementMethod.momo,
        ),
      ]);
      await tester.pumpAndSettle();

      expect(_deleteButton(tester).onPressed, isNull);
      expect(_statusOf(tester, 'bob'), 'Paid with Mobile Money');
    });
  });
}
