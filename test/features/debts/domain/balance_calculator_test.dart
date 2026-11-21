import 'package:changa_app/core/enums/settlement_method.dart';
import 'package:changa_app/features/debts/domain/entities/balance_summary.dart';
import 'package:changa_app/features/debts/domain/entities/debt.dart';
import 'package:changa_app/features/debts/domain/entities/debt_status.dart';
import 'package:changa_app/features/debts/domain/logic/balance_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_data.dart';

void main() {
  const calculator = BalanceCalculator();
  const me = 'me';

  BalanceSummary summarize(List<Debt> debts) {
    return calculator.summarize(pendingDebts: debts, meUid: me);
  }

  group('BalanceCalculator', () {
    test('one-way debt owed to me is positive', () {
      final result = summarize([
        testDebt(debtorUid: 'kevin', creditorUid: me, amount: 6000),
      ]);

      _expectSummary(
        result,
        byMember: {'kevin': 6000},
        youAreOwed: 6000,
        youOwe: 0,
        net: 6000,
      );
    });

    test('one-way debt I owe is negative', () {
      final result = summarize([
        testDebt(debtorUid: me, creditorUid: 'grace', amount: 4000),
      ]);

      _expectSummary(
        result,
        byMember: {'grace': -4000},
        youAreOwed: 0,
        youOwe: 4000,
        net: -4000,
      );
    });

    test('debts in both directions are netted per person', () {
      final result = summarize([
        testDebt(debtorUid: 'kevin', creditorUid: me, amount: 6000),
        testDebt(
          id: 'debt-2',
          debtorUid: me,
          creditorUid: 'kevin',
          amount: 2000,
        ),
      ]);

      _expectSummary(
        result,
        byMember: {'kevin': 4000},
        youAreOwed: 4000,
        youOwe: 0,
        net: 4000,
      );
    });

    test('several expenses with one person are combined', () {
      final result = summarize([
        testDebt(debtorUid: 'kevin', creditorUid: me, amount: 6000),
        testDebt(
          id: 'debt-2',
          expenseId: 'expense-2',
          debtorUid: 'kevin',
          creditorUid: me,
          amount: 5000,
        ),
        testDebt(
          id: 'debt-3',
          expenseId: 'expense-3',
          debtorUid: 'kevin',
          creditorUid: me,
          amount: 3000,
        ),
      ]);

      _expectSummary(
        result,
        byMember: {'kevin': 14000},
        youAreOwed: 14000,
        youOwe: 0,
        net: 14000,
      );
    });

    test('equal opposing debts keep a zero member balance', () {
      final result = summarize([
        testDebt(debtorUid: 'kevin', creditorUid: me, amount: 6000),
        testDebt(
          id: 'debt-2',
          debtorUid: me,
          creditorUid: 'kevin',
          amount: 6000,
        ),
      ]);

      _expectSummary(
        result,
        byMember: {'kevin': 0},
        youAreOwed: 0,
        youOwe: 0,
        net: 0,
      );
    });

    test('settled debts are ignored', () {
      final result = summarize([
        testDebt(
          debtorUid: 'kevin',
          creditorUid: me,
          amount: 9000,
          status: DebtStatus.settled,
          settledAt: DateTime.utc(2026, 10, 21),
        ),
        testDebt(
          id: 'debt-2',
          debtorUid: 'kevin',
          creditorUid: me,
          amount: 2000,
        ),
      ]);

      _expectSummary(
        result,
        byMember: {'kevin': 2000},
        youAreOwed: 2000,
        youOwe: 0,
        net: 2000,
      );
    });

    test('debts settled by credits are ignored', () {
      final result = summarize([
        testDebt(
          debtorUid: me,
          creditorUid: 'grace',
          amount: 0,
          status: DebtStatus.settled,
          settledAt: DateTime.utc(2026, 10, 21),
          settlementMethod: SettlementMethod.credits,
          creditsApplied: 200,
        ),
      ]);

      _expectSummary(result, byMember: {}, youAreOwed: 0, youOwe: 0, net: 0);
    });

    test('unknown member UID is preserved', () {
      final result = summarize([
        testDebt(debtorUid: 'removed-member', creditorUid: me, amount: 1500),
      ]);

      _expectSummary(
        result,
        byMember: {'removed-member': 1500},
        youAreOwed: 1500,
        youOwe: 0,
        net: 1500,
      );
    });

    test('empty debts produce an empty zero summary', () {
      final result = summarize([]);

      _expectSummary(result, byMember: {}, youAreOwed: 0, youOwe: 0, net: 0);
    });

    test('totals use each member net without cancelling different people', () {
      final result = summarize([
        testDebt(debtorUid: 'kevin', creditorUid: me, amount: 6000),
        testDebt(
          id: 'debt-2',
          debtorUid: me,
          creditorUid: 'kevin',
          amount: 2000,
        ),
        testDebt(
          id: 'debt-3',
          debtorUid: me,
          creditorUid: 'grace',
          amount: 3000,
        ),
      ]);

      _expectSummary(
        result,
        byMember: {'kevin': 4000, 'grace': -3000},
        youAreOwed: 4000,
        youOwe: 3000,
        net: 1000,
      );
    });

    test('debts between other people and self-debts are ignored', () {
      final result = summarize([
        testDebt(debtorUid: 'kevin', creditorUid: 'grace', amount: 6000),
        testDebt(id: 'debt-2', debtorUid: me, creditorUid: me, amount: 3000),
      ]);

      _expectSummary(result, byMember: {}, youAreOwed: 0, youOwe: 0, net: 0);
    });
  });
}

void _expectSummary(
  BalanceSummary actual, {
  required Map<String, int> byMember,
  required int youAreOwed,
  required int youOwe,
  required int net,
}) {
  expect(actual.byMember, equals(byMember));
  expect(actual.youAreOwed, youAreOwed);
  expect(actual.youOwe, youOwe);
  expect(actual.net, net);
}
