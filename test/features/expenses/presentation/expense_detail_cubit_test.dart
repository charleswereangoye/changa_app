// Owner: C - Person C (Expenses, Dashboard, Documentation)
// Description: Tests for ExpenseDetailCubit (shares, edit note, delete guards)

import 'dart:async';

import 'package:changa_app/core/enums/settlement_method.dart';
import 'package:changa_app/core/error/failures.dart';
import 'package:changa_app/core/error/result.dart';
import 'package:changa_app/features/debts/domain/entities/debt.dart';
import 'package:changa_app/features/debts/domain/entities/debt_status.dart';
import 'package:changa_app/features/expenses/domain/entities/expense.dart';
import 'package:changa_app/features/expenses/domain/entities/expense_category.dart';
import 'package:changa_app/features/expenses/domain/entities/new_expense_input.dart';
import 'package:changa_app/features/expenses/domain/entities/split_type.dart';
import 'package:changa_app/features/expenses/domain/logic/expense_shares.dart';
import 'package:changa_app/features/expenses/domain/repositories/expense_repository.dart';
import 'package:changa_app/features/expenses/domain/usecases/delete_expense.dart';
import 'package:changa_app/features/expenses/domain/usecases/update_expense_note.dart';
import 'package:changa_app/features/expenses/domain/usecases/watch_expense_debts.dart';
import 'package:changa_app/features/expenses/presentation/cubit/expense_detail_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeDetailRepository implements ExpenseRepository {
  FakeDetailRepository({this.debtsNow = const [], this.debtsNeverLoad = false});

  /// What the debts stream gives first.
  final List<Debt> debtsNow;

  /// When true the debts stream never emits, so payments stay "loading".
  final bool debtsNeverLoad;

  int updateCalls = 0;
  int deleteCalls = 0;
  String? lastTitle;
  String? lastNote;

  /// When set, update and delete wait until the test completes it.
  Completer<Result<void>>? gate;
  Result<void> nextResult = Result<void>.success(null);

  late final StreamController<List<Debt>> debtController =
      StreamController<List<Debt>>.broadcast(
        onListen: () {
          if (!debtsNeverLoad) {
            scheduleMicrotask(() => debtController.add(debtsNow));
          }
        },
      );

  @override
  Stream<List<Debt>> watchExpenseDebts({
    required String householdId,
    required String expenseId,
  }) => debtController.stream;

  @override
  Future<Result<void>> updateExpenseNote({
    required String householdId,
    required String expenseId,
    required String title,
    String? note,
  }) {
    updateCalls++;
    lastTitle = title;
    lastNote = note;
    return gate?.future ?? Future.value(nextResult);
  }

  @override
  Future<Result<void>> deleteExpense({
    required String householdId,
    required String expenseId,
  }) {
    deleteCalls++;
    return gate?.future ?? Future.value(nextResult);
  }

  @override
  Future<Result<Expense>> addExpense(NewExpenseInput input) =>
      throw UnimplementedError();

  @override
  Stream<List<Expense>> watchExpenses(String householdId) =>
      throw UnimplementedError();
}

Expense sample({String paidBy = 'amara', String? note}) => Expense(
  id: 'e1',
  title: 'Groceries',
  note: note,
  category: ExpenseCategory.groceries,
  totalAmount: 12000,
  paidByUid: paidBy,
  splitType: SplitType.equal,
  createdAt: DateTime(2026, 10, 30),
);

Debt debt(
  String debtor,
  int amount, {
  int credits = 0,
  DebtStatus status = DebtStatus.pending,
  SettlementMethod? method,
}) => Debt(
  id: 'd-$debtor',
  expenseId: 'e1',
  debtorUid: debtor,
  creditorUid: 'amara',
  amount: amount,
  creditsApplied: credits,
  status: status,
  settlementMethod: method,
  settledAt: status == DebtStatus.settled ? DateTime(2026, 10, 31) : null,
  createdAt: DateTime(2026, 10, 30),
);

/// Builds the cubit and waits for the first debts to arrive.
Future<ExpenseDetailCubit> build(
  FakeDetailRepository repo, {
  String currentUid = 'amara',
  Expense? expense,
}) async {
  final cubit = ExpenseDetailCubit(
    updateExpenseNote: UpdateExpenseNote(repo),
    deleteExpense: DeleteExpense(repo),
    watchExpenseDebts: WatchExpenseDebts(repo),
    householdId: 'h1',
    expense: expense ?? sample(),
    currentUid: currentUid,
  );
  await pumpEventQueue();
  return cubit;
}

Future<void> pushDebts(FakeDetailRepository repo, List<Debt> debts) async {
  repo.debtController.add(debts);
  await pumpEventQueue();
}

void main() {
  late FakeDetailRepository repo;

  setUp(() => repo = FakeDetailRepository());

  test('the payer can manage the expense, others cannot', () async {
    expect((await build(repo)).state.canManage, isTrue);
    expect((await build(repo, currentUid: 'chloe')).state.canManage, isFalse);
  });

  test('startEdit copies the saved title and note into the draft', () async {
    final cubit = await build(repo, expense: sample(note: 'Market run'));
    cubit.startEdit();

    expect(cubit.state.status, ExpenseDetailStatus.editing);
    expect(cubit.state.titleDraft, 'Groceries');
    expect(cubit.state.noteDraft, 'Market run');
  });

  test('someone who did not pay cannot edit or delete', () async {
    final cubit = await build(repo, currentUid: 'chloe');
    cubit.startEdit();
    await cubit.delete();

    expect(cubit.state.status, ExpenseDetailStatus.viewing);
    expect(repo.updateCalls, 0);
    expect(repo.deleteCalls, 0);
  });

  test('cancelEdit goes back to viewing', () async {
    final cubit = await build(repo);
    cubit.startEdit();
    cubit.titleChanged('Something else');
    cubit.cancelEdit();

    expect(cubit.state.status, ExpenseDetailStatus.viewing);
    expect(cubit.state.expense.title, 'Groceries');
  });

  test('save sends trimmed title, a blank note as null, and updates', () async {
    final cubit = await build(repo);
    cubit.startEdit();
    cubit.titleChanged('  Weekly groceries  ');
    cubit.noteChanged('   ');
    await cubit.save();

    expect(repo.lastTitle, 'Weekly groceries');
    expect(repo.lastNote, isNull);
    expect(cubit.state.status, ExpenseDetailStatus.saved);
    expect(cubit.state.expense.title, 'Weekly groceries');
    expect(cubit.state.expense.note, isNull);
    expect(cubit.state.expense.totalAmount, 12000);
  });

  test('a title that is too short cannot be saved', () async {
    final cubit = await build(repo);
    cubit.startEdit();
    cubit.titleChanged('ab');

    expect(cubit.state.titleProblem, isNotNull);
    expect(cubit.state.canSave, isFalse);
    await cubit.save();
    expect(repo.updateCalls, 0);
  });

  test('saving without any change does nothing', () async {
    final cubit = await build(repo);
    cubit.startEdit();
    await cubit.save();

    expect(repo.updateCalls, 0);
    expect(cubit.state.status, ExpenseDetailStatus.editing);
  });

  test('a failed save keeps the draft and shows the failure', () async {
    repo.nextResult = Result<void>.failure(const NetworkFailure());
    final cubit = await build(repo);
    cubit.startEdit();
    cubit.titleChanged('Weekly groceries');
    await cubit.save();

    expect(cubit.state.status, ExpenseDetailStatus.editing);
    expect(cubit.state.titleDraft, 'Weekly groceries');
    expect(cubit.state.failure, isA<NetworkFailure>());
    expect(cubit.state.expense.title, 'Groceries');
  });

  test('edits are ignored while a save is in flight', () async {
    repo.gate = Completer<Result<void>>();
    final cubit = await build(repo);
    cubit.startEdit();
    cubit.titleChanged('Weekly groceries');
    final saving = cubit.save();

    cubit.titleChanged('Changed mid-save');
    cubit.cancelEdit();
    expect(cubit.state.status, ExpenseDetailStatus.saving);
    expect(cubit.state.titleDraft, 'Weekly groceries');

    repo.gate!.complete(Result<void>.success(null));
    await saving;
    expect(repo.updateCalls, 1);
  });

  test('closing the cubit during a save does not throw', () async {
    repo.gate = Completer<Result<void>>();
    final cubit = await build(repo);
    cubit.startEdit();
    cubit.titleChanged('Weekly groceries');
    final saving = cubit.save();

    await cubit.close();
    repo.gate!.complete(Result<void>.success(null));
    await saving;
  });

  group('per-person shares', () {
    test('lists the payer and everyone who owes, with their status', () async {
      repo = FakeDetailRepository(
        debtsNow: [
          debt('bob', 600, credits: 340),
          debt(
            'chloe',
            4000,
            status: DebtStatus.settled,
            method: SettlementMethod.cash,
          ),
        ],
      );
      final cubit = await build(repo);

      expect(cubit.state.debtsStatus, ExpenseDebtsStatus.ready);
      final shares = cubit.state.shares;
      expect(shares.map((s) => s.uid), ['amara', 'bob', 'chloe']);
      expect(shares[0].payment, SharePayment.payer);
      expect(shares[0].amount, 4000);
      expect(shares[1].amount, 4000);
      expect(shares[1].amountDue, 600);
      expect(shares[1].payment, SharePayment.pending);
      expect(shares[2].payment, SharePayment.paid);
    });

    test('a payment arriving later updates the shares', () async {
      repo = FakeDetailRepository(debtsNow: [debt('bob', 4000)]);
      final cubit = await build(repo);
      expect(cubit.state.shares[1].payment, SharePayment.pending);

      await pushDebts(repo, [
        debt(
          'bob',
          4000,
          status: DebtStatus.settled,
          method: SettlementMethod.momo,
        ),
      ]);

      expect(cubit.state.shares[1].payment, SharePayment.paid);
    });
  });

  group('delete', () {
    test('succeeds and ends in deleted', () async {
      final cubit = await build(repo);
      await cubit.delete();

      expect(repo.deleteCalls, 1);
      expect(cubit.state.status, ExpenseDetailStatus.deleted);
    });

    test('a failed delete goes back to viewing with the failure', () async {
      repo.nextResult = Result<void>.failure(
        const ValidationFailure('Someone already paid their share.'),
      );
      final cubit = await build(repo);
      await cubit.delete();

      expect(cubit.state.status, ExpenseDetailStatus.viewing);
      expect(cubit.state.failure, isA<ValidationFailure>());
    });

    test('tapping delete twice only deletes once', () async {
      repo.gate = Completer<Result<void>>();
      final cubit = await build(repo);
      final first = cubit.delete();
      final second = cubit.delete();

      repo.gate!.complete(Result<void>.success(null));
      await Future.wait([first, second]);
      expect(repo.deleteCalls, 1);
    });

    test('is blocked, with a reason, once a debt was paid', () async {
      repo = FakeDetailRepository(
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
      final cubit = await build(repo);

      expect(cubit.state.canDelete, isFalse);
      expect(
        cubit.state.deleteBlockedReason,
        'One housemate has already paid their share, so this expense can no '
        'longer be deleted.',
      );

      await cubit.delete();
      expect(repo.deleteCalls, 0);
      expect(cubit.state.status, ExpenseDetailStatus.viewing);
    });

    test('the reason counts several paid housemates', () async {
      repo = FakeDetailRepository(
        debtsNow: [
          debt(
            'bob',
            4000,
            status: DebtStatus.settled,
            method: SettlementMethod.cash,
          ),
          debt(
            'chloe',
            4000,
            status: DebtStatus.settled,
            method: SettlementMethod.momo,
          ),
        ],
      );
      final cubit = await build(repo);

      expect(cubit.state.deleteBlockedReason, startsWith('2 housemates'));
    });

    test('a debt fully covered by credits does not block it', () async {
      repo = FakeDetailRepository(
        debtsNow: [
          debt(
            'bob',
            0,
            credits: 400,
            status: DebtStatus.settled,
            method: SettlementMethod.credits,
          ),
        ],
      );
      final cubit = await build(repo);

      expect(cubit.state.canDelete, isTrue);
      await cubit.delete();
      expect(repo.deleteCalls, 1);
    });

    test('is off while the payments are still loading', () async {
      repo = FakeDetailRepository(debtsNeverLoad: true);
      final cubit = await build(repo);

      expect(cubit.state.debtsStatus, ExpenseDebtsStatus.loading);
      expect(cubit.state.canDelete, isFalse);
      await cubit.delete();
      expect(repo.deleteCalls, 0);
    });

    test('a payment that lands later switches it off', () async {
      repo = FakeDetailRepository(debtsNow: [debt('bob', 4000)]);
      final cubit = await build(repo);
      expect(cubit.state.canDelete, isTrue);

      await pushDebts(repo, [
        debt(
          'bob',
          4000,
          status: DebtStatus.settled,
          method: SettlementMethod.bank,
        ),
      ]);

      expect(cubit.state.canDelete, isFalse);
      expect(cubit.state.deleteBlockedReason, isNotNull);
    });

    test('stays blocked if reloading the debts fails afterwards', () async {
      repo = FakeDetailRepository(
        debtsNow: [
          debt(
            'bob',
            4000,
            status: DebtStatus.settled,
            method: SettlementMethod.cash,
          ),
        ],
      );
      final cubit = await build(repo);

      repo.debtController.addError(Exception('offline'));
      await pumpEventQueue();

      expect(cubit.state.debtsStatus, ExpenseDebtsStatus.failed);
      expect(cubit.state.canDelete, isFalse);
    });

    test(
      'stays available if the debts cannot load (data layer decides)',
      () async {
        final cubit = await build(repo);

        repo.debtController.addError(Exception('offline'));
        await pumpEventQueue();

        expect(cubit.state.debtsStatus, ExpenseDebtsStatus.failed);
        expect(cubit.state.shares, isEmpty);
        expect(cubit.state.canDelete, isTrue);

        // It recovers when the debts load again.
        await pushDebts(repo, [debt('bob', 4000)]);
        expect(cubit.state.debtsStatus, ExpenseDebtsStatus.ready);
        expect(cubit.state.shares, hasLength(2));
      },
    );

    test(
      'data layer refusing a concurrent payment shows its message',
      () async {
        // The UI thought nothing was paid, the data layer knows better.
        repo.nextResult = Result<void>.failure(
          const ValidationFailure('A housemate already paid their share.'),
        );
        final cubit = await build(repo);
        await cubit.delete();

        expect(repo.deleteCalls, 1);
        expect(cubit.state.status, ExpenseDetailStatus.viewing);
        expect(
          cubit.state.failure?.message,
          'A housemate already paid their share.',
        );
      },
    );
  });

  test('closing the cubit stops listening to the debts', () async {
    final cubit = await build(repo);
    expect(repo.debtController.hasListener, isTrue);

    await cubit.close();

    expect(repo.debtController.hasListener, isFalse);
  });
}
