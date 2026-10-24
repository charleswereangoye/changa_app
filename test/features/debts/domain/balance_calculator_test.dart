// Tests balance netting, settled debts, and whole-RWF validation.

import 'package:changa_app/core/enums/settlement_method.dart';
import 'package:changa_app/features/debts/domain/entities/balance_summary.dart';
import 'package:changa_app/features/debts/domain/entities/debt.dart';
import 'package:changa_app/features/debts/domain/entities/debt_status.dart';
import 'package:changa_app/features/debts/domain/logic/balance_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const calculator = BalanceCalculator();
  const me = 'me';

  BalanceSummary summarize(List<Debt> debts) {
    return calculator.summarize(pendingDebts: debts, meUid: me);
  }

  group('BalanceCalculator', () {
    test('one-way debt owed to me is positive', () {
      final result = summarize([_debt(from: 'kevin', to: me, amount: 6000)]);

      _expectSummary(
        result,
        byMember: {'kevin': 6000},
        youAreOwed: 6000,
        youOwe: 0,
        net: 6000,
      );
    });

    test('one-way debt I owe is negative', () {
      final result = summarize([_debt(from: me, to: 'grace', amount: 4000)]);

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
        _debt(from: 'kevin', to: me, amount: 6000),
        _debt(from: me, to: 'kevin', amount: 2000),
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
        _debt(from: 'kevin', to: me, amount: 6000),
        _debt(from: 'kevin', to: me, amount: 5000),
        _debt(from: 'kevin', to: me, amount: 3000),
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
        _debt(from: 'kevin', to: me, amount: 6000),
        _debt(from: me, to: 'kevin', amount: 6000),
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
        _debt(from: 'kevin', to: me, amount: 9000, status: DebtStatus.settled),
        _debt(from: 'kevin', to: me, amount: 2000),
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
        _debt(
          from: me,
          to: 'grace',
          amount: 0,
          status: DebtStatus.settled,
          method: SettlementMethod.credits,
        ),
      ]);

      _expectSummary(result, byMember: {}, youAreOwed: 0, youOwe: 0, net: 0);
    });

    test('unknown member UID is preserved', () {
      final result = summarize([
        _debt(from: 'removed-member', to: me, amount: 1500),
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
        _debt(from: 'kevin', to: me, amount: 6000),
        _debt(from: me, to: 'kevin', amount: 2000),
        _debt(from: me, to: 'grace', amount: 3000),
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
        _debt(from: 'kevin', to: 'grace', amount: 6000),
        _debt(from: me, to: me, amount: 3000),
      ]);

      _expectSummary(result, byMember: {}, youAreOwed: 0, youOwe: 0, net: 0);
    });

    test('fractional RWF is rejected instead of truncated', () {
      expect(
        () => summarize([_debt(from: 'kevin', to: me, amount: 1500.5)]),
        throwsFormatException,
      );
    });

    test('negative and non-finite amounts are rejected', () {
      for (final amount in [
        -1.0,
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        expect(
          () => summarize([_debt(from: 'kevin', to: me, amount: amount)]),
          throwsFormatException,
          reason: 'Invalid amount: $amount',
        );
      }
    });
  });
}

/// Creates a debt fixture using the current shared entity.
Debt _debt({
  required String from,
  required String to,
  required double amount,
  DebtStatus status = DebtStatus.pending,
  SettlementMethod? method,
}) {
  return Debt(
    id: 'debt-$from-$to-$amount',
    householdId: 'household-1',
    fromUid: from,
    toUid: to,
    amount: amount,
    status: status,
    createdAt: DateTime.utc(2026, 10, 20),
    settledAt: status == DebtStatus.settled ? DateTime.utc(2026, 10, 21) : null,
    settledMethod: method,
  );
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
