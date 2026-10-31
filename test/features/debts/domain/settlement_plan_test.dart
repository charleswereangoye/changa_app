// Tests which debts are settled and how their net amount is calculated.

import 'package:changa_app/features/debts/domain/entities/debt.dart';
import 'package:changa_app/features/debts/domain/entities/debt_status.dart';
import 'package:changa_app/features/debts/domain/logic/settlement_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  SettlementPlan plan(List<Debt> debts) {
    return SettlementPlan.between(debts: debts, meUid: 'me', otherUid: 'kevin');
  }

  group('SettlementPlan', () {
    test('empty debts produce an empty plan', () {
      final result = plan([]);

      expect(result.isEmpty, isTrue);
      expect(result.debtIds, isEmpty);
      expect(result.netAmount, 0);
      expect(result.amount, 0);
    });

    test('debt owed to me produces a positive net amount', () {
      final result = plan([
        _debt(id: 'a', from: 'kevin', to: 'me', amount: 6000),
      ]);

      expect(result.debtIds, ['a']);
      expect(result.netAmount, 6000);
      expect(result.amount, 6000);
      expect(result.isEmpty, isFalse);
    });

    test('debt I owe produces a negative net amount', () {
      final result = plan([
        _debt(id: 'a', from: 'me', to: 'kevin', amount: 4000),
      ]);

      expect(result.debtIds, ['a']);
      expect(result.netAmount, -4000);
      expect(result.amount, 4000);
    });

    test('both directions are included with one net amount', () {
      final result = plan([
        _debt(id: 'a', from: 'kevin', to: 'me', amount: 6000),
        _debt(id: 'b', from: 'me', to: 'kevin', amount: 2000),
      ]);

      expect(result.debtIds, unorderedEquals(['a', 'b']));
      expect(result.netAmount, 4000);
      expect(result.amount, 4000);
    });

    test('zero net still includes both pending debts for settlement', () {
      final result = plan([
        _debt(id: 'a', from: 'kevin', to: 'me', amount: 6000),
        _debt(id: 'b', from: 'me', to: 'kevin', amount: 6000),
      ]);

      expect(result.debtIds, unorderedEquals(['a', 'b']));
      expect(result.netAmount, 0);
      expect(result.amount, 0);
      expect(result.isEmpty, isFalse);
    });

    test('settled debts and debts involving other people are excluded', () {
      final result = plan([
        _debt(
          id: 'settled',
          from: 'kevin',
          to: 'me',
          amount: 9000,
          status: DebtStatus.settled,
        ),
        _debt(id: 'other', from: 'grace', to: 'me', amount: 3000),
        _debt(id: 'self', from: 'me', to: 'me', amount: 1000),
        _debt(id: 'pending', from: 'kevin', to: 'me', amount: 2000),
      ]);

      expect(result.debtIds, ['pending']);
      expect(result.netAmount, 2000);
    });

    test('a repeated document is only counted once', () {
      final debt = _debt(
        id: 'same-document',
        from: 'kevin',
        to: 'me',
        amount: 6000,
      );

      final result = plan([debt, debt]);

      expect(result.debtIds, ['same-document']);
      expect(result.netAmount, 6000);
    });

    test('empty member IDs and settling with yourself are rejected', () {
      for (final pair in [('', 'kevin'), ('me', ''), ('me', 'me')]) {
        expect(
          () => SettlementPlan.between(
            debts: [],
            meUid: pair.$1,
            otherUid: pair.$2,
          ),
          throwsArgumentError,
        );
      }
    });

    test('debt IDs cannot be changed after creating the plan', () {
      final result = plan([
        _debt(id: 'a', from: 'kevin', to: 'me', amount: 6000),
      ]);

      expect(() => result.debtIds.add('another-debt'), throwsUnsupportedError);
    });
  });
}

Debt _debt({
  required String id,
  required String from,
  required String to,
  required int amount,
  DebtStatus status = DebtStatus.pending,
}) {
  return Debt(
    id: id,
    expenseId: 'expense-$id',
    debtorUid: from,
    creditorUid: to,
    amount: amount,
    creditsApplied: 0,
    status: status,
    createdAt: DateTime.utc(2026, 10, 20),
    settledAt: status == DebtStatus.settled ? DateTime.utc(2026, 10, 21) : null,
  );
}
