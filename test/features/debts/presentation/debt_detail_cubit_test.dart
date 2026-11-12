import 'dart:async';

import 'package:changa_app/core/error/failures.dart';
import 'package:changa_app/core/error/result.dart';
import 'package:changa_app/features/debts/domain/entities/debt.dart';
import 'package:changa_app/features/debts/domain/entities/debt_status.dart';
import 'package:changa_app/features/debts/domain/usecases/send_nudge.dart';
import 'package:changa_app/features/debts/domain/usecases/watch_debts_between.dart';
import 'package:changa_app/features/debts/presentation/cubit/debt_detail_cubit.dart';
import 'package:changa_app/features/expenses/domain/entities/expense.dart';
import 'package:changa_app/features/expenses/domain/entities/expense_category.dart';
import 'package:changa_app/features/expenses/domain/entities/split_type.dart';
import 'package:changa_app/features/expenses/domain/usecases/watch_expenses.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockWatchDebtsBetween extends Mock implements WatchDebtsBetween {}

class _MockWatchExpenses extends Mock implements WatchExpenses {}

class _MockSendNudge extends Mock implements SendNudge {}

Debt _debt(
  String id, {
  String debtor = 'kevin',
  String creditor = 'me',
  int amount = 6000,
  int creditsApplied = 0,
  DebtStatus status = DebtStatus.pending,
  int day = 1,
}) {
  return Debt(
    id: id,
    expenseId: 'expense-1',
    debtorUid: debtor,
    creditorUid: creditor,
    amount: amount,
    creditsApplied: creditsApplied,
    status: status,
    createdAt: DateTime.utc(2026, 11, day),
  );
}

void main() {
  late _MockWatchDebtsBetween watchDebts;
  late _MockWatchExpenses watchExpenses;
  late _MockSendNudge sendNudge;
  late StreamController<List<Debt>> debts;
  late StreamController<List<Expense>> expenses;
  late DebtDetailCubit cubit;

  final expense = Expense(
    id: 'expense-1',
    title: 'Groceries',
    category: ExpenseCategory.groceries,
    totalAmount: 24000,
    paidByUid: 'me',
    splitType: SplitType.equal,
    createdAt: DateTime.utc(2026, 11, 1),
  );

  setUp(() {
    watchDebts = _MockWatchDebtsBetween();
    watchExpenses = _MockWatchExpenses();
    sendNudge = _MockSendNudge();

    debts = StreamController<List<Debt>>.broadcast(sync: true);
    expenses = StreamController<List<Expense>>.broadcast(sync: true);

    when(() => watchDebts('home', 'me', 'kevin'))
        .thenAnswer((_) => debts.stream);

    when(() => watchExpenses('home')).thenAnswer((_) => expenses.stream);

    when(() => sendNudge(householdId: 'home', fromUid: 'me', toUid: 'kevin'))
        .thenAnswer((_) async => Result<void>.success(null));

    cubit = DebtDetailCubit(
      watchDebtsBetween: watchDebts,
      watchExpenses: watchExpenses,
      sendNudge: sendNudge,
      householdId: 'home',
      meUid: 'me',
      otherUid: 'kevin',
    );
  });

  tearDown(() async {
    if (!cubit.isClosed) {
      await cubit.close();
    }
    await debts.close();
    await expenses.close();
  });

  Future<void> ready(List<Debt> items) async {
    await cubit.load();
    debts.add(items);
    expenses.add([expense]);
    await pumpEventQueue();
  }

  test('starts with no available actions', () {
    expect(cubit.state.status, DebtDetailStatus.initial);
    expect(cubit.state.canNudge, isFalse);
    expect(cubit.state.canSettle, isFalse);
  });

  test('waits for both debts and expenses', () async {
    await cubit.load();

    debts.add([_debt('debt-1')]);
    await pumpEventQueue();

    expect(cubit.state.status, DebtDetailStatus.loading);

    expenses.add([expense]);
    await pumpEventQueue();

    expect(cubit.state.status, DebtDetailStatus.loaded);
    expect(cubit.state.expensesById['expense-1']?.title, 'Groceries');
  });

  test(
    'nets both directions and excludes settled or unrelated debts',
    () async {
      await ready([
        _debt('incoming', amount: 14000),
        _debt('outgoing', debtor: 'me', creditor: 'kevin', amount: 4000),
        _debt('settled', amount: 9000, status: DebtStatus.settled),
        _debt('unrelated', debtor: 'grace', creditor: 'jean'),
      ]);

      expect(cubit.state.netBalance, 10000);
      expect(cubit.state.debts.map((debt) => debt.id).toSet(), {
        'incoming',
        'outgoing',
      });
      expect(cubit.state.canNudge, isTrue);
      expect(cubit.state.canSettle, isTrue);
    },
  );

  test('sorts newest first and retains applied credits', () async {
    await ready([
      _debt('older', day: 1),
      _debt('newer', day: 2, creditsApplied: 20),
    ]);

    expect(cubit.state.debts.map((debt) => debt.id).toList(), [
      'newer',
      'older',
    ]);
    expect(cubit.state.debts.first.creditsApplied, 20);
  });

  test('an empty balance disables nudge and settlement', () async {
    await ready([]);

    expect(cubit.state.netBalance, 0);
    expect(cubit.state.canNudge, isFalse);
    expect(cubit.state.canSettle, isFalse);
  });

  test('cannot nudge when I owe the other member', () async {
    await ready([_debt('outgoing', debtor: 'me', creditor: 'kevin')]);

    expect(cubit.state.netBalance, -6000);
    expect(cubit.state.canNudge, isFalse);

    await cubit.sendNudge();

    verifyZeroInteractions(sendNudge);
  });

  test('cannot nudge when opposing debts net to zero', () async {
    await ready([
      _debt('incoming'),
      _debt('outgoing', debtor: 'me', creditor: 'kevin'),
    ]);

    expect(cubit.state.netBalance, 0);
    expect(cubit.state.canNudge, isFalse);

    // Both pending debts can still be marked settled together.
    expect(cubit.state.canSettle, isTrue);

    await cubit.sendNudge();

    verifyZeroInteractions(sendNudge);
  });

  test('sends a nudge for the current pair', () async {
    await ready([_debt('incoming')]);

    await cubit.sendNudge();

    expect(cubit.state.nudgeStatus, NudgeStatus.sent);
    expect(cubit.state.nudgeFailure, isNull);

    verify(() => sendNudge(householdId: 'home', fromUid: 'me', toUid: 'kevin'))
        .called(1);
  });

  test('preserves the cooldown failure for the screen', () async {
    const failure = NudgeCooldownFailure();

    when(() => sendNudge(householdId: 'home', fromUid: 'me', toUid: 'kevin'))
        .thenAnswer((_) async => Result<void>.failure(failure));

    await ready([_debt('incoming')]);
    await cubit.sendNudge();

    expect(cubit.state.nudgeStatus, NudgeStatus.failure);
    expect(cubit.state.nudgeFailure, same(failure));
    expect(cubit.state.status, DebtDetailStatus.loaded);
    expect(cubit.state.debts, hasLength(1));
  });

  test('live updates cannot enable a second in-flight nudge', () async {
    final gate = Completer<Result<void>>();

    when(() => sendNudge(householdId: 'home', fromUid: 'me', toUid: 'kevin'))
        .thenAnswer((_) => gate.future);

    await ready([_debt('incoming')]);

    final sending = cubit.sendNudge();

    expect(cubit.state.nudgeStatus, NudgeStatus.sending);

    debts.add([_debt('incoming', amount: 8000)]);
    await pumpEventQueue();

    expect(cubit.state.netBalance, 8000);
    expect(cubit.state.nudgeStatus, NudgeStatus.sending);
    expect(cubit.state.canNudge, isFalse);

    await cubit.sendNudge();

    gate.complete(Result<void>.success(null));
    await sending;

    verify(() => sendNudge(householdId: 'home', fromUid: 'me', toUid: 'kevin'))
        .called(1);
  });

  test('stream failure disables actions and retry can recover', () async {
    await ready([_debt('incoming')]);

    const failure = NetworkFailure();
    debts.addError(failure);
    await pumpEventQueue();

    expect(cubit.state.status, DebtDetailStatus.failure);
    expect(cubit.state.failure, same(failure));
    expect(cubit.state.canNudge, isFalse);
    expect(cubit.state.canSettle, isFalse);

    await cubit.retry();

    debts.add([_debt('incoming')]);
    expenses.add([expense]);
    await pumpEventQueue();

    expect(cubit.state.status, DebtDetailStatus.loaded);
    expect(cubit.state.failure, isNull);
  });

  test('retry recovers during a nudge without sending it twice', () async {
    final gate = Completer<Result<void>>();

    when(() => sendNudge(householdId: 'home', fromUid: 'me', toUid: 'kevin'))
        .thenAnswer((_) => gate.future);

    await ready([_debt('incoming')]);

    final sending = cubit.sendNudge();

    debts.addError(const NetworkFailure());
    await pumpEventQueue();

    expect(cubit.state.status, DebtDetailStatus.failure);
    expect(cubit.state.nudgeStatus, NudgeStatus.sending);

    await cubit.retry();

    expect(cubit.state.status, DebtDetailStatus.loading);
    expect(cubit.state.failure, isNull);
    expect(cubit.state.nudgeStatus, NudgeStatus.sending);

    debts.add([_debt('incoming', amount: 8000)]);
    expenses.add([expense]);
    await pumpEventQueue();

    expect(cubit.state.status, DebtDetailStatus.loaded);
    expect(cubit.state.netBalance, 8000);
    expect(cubit.state.canNudge, isFalse);
    expect(cubit.state.canSettle, isFalse);

    await cubit.sendNudge();

    gate.complete(Result<void>.success(null));
    await sending;

    expect(cubit.state.nudgeStatus, NudgeStatus.sent);
    expect(cubit.state.canSettle, isTrue);

    verify(() => watchDebts('home', 'me', 'kevin')).called(2);
    verify(() => sendNudge(householdId: 'home', fromUid: 'me', toUid: 'kevin'))
        .called(1);
  });

  test('closing during a nudge ignores its late result', () async {
    final gate = Completer<Result<void>>();

    when(() => sendNudge(householdId: 'home', fromUid: 'me', toUid: 'kevin'))
        .thenAnswer((_) => gate.future);

    await ready([_debt('incoming')]);

    final sending = cubit.sendNudge();
    await cubit.close();

    expect(debts.hasListener, isFalse);
    expect(expenses.hasListener, isFalse);

    gate.complete(Result<void>.success(null));
    await sending;

    expect(cubit.isClosed, isTrue);
  });
}
