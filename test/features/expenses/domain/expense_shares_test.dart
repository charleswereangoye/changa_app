// Owner: C - Person C (Expenses, Dashboard, Documentation)
// Description: Tests for the per-person share breakdown of an expense

import 'package:changa_app/core/enums/settlement_method.dart';
import 'package:changa_app/features/debts/domain/entities/debt.dart';
import 'package:changa_app/features/debts/domain/entities/debt_status.dart';
import 'package:changa_app/features/expenses/domain/entities/expense.dart';
import 'package:changa_app/features/expenses/domain/entities/expense_category.dart';
import 'package:changa_app/features/expenses/domain/entities/split_type.dart';
import 'package:changa_app/features/expenses/domain/logic/expense_shares.dart';
import 'package:flutter_test/flutter_test.dart';

final _expense = Expense(
  id: 'e1',
  title: 'Groceries',
  category: ExpenseCategory.groceries,
  totalAmount: 12000,
  paidByUid: 'amara',
  splitType: SplitType.equal,
  createdAt: DateTime(2026, 10, 30),
);

Debt _debt(
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
  createdAt: DateTime(2026, 10, 30),
);

void main() {
  test('the payer comes first and gets what is left of the total', () {
    final shares = ExpenseShares.from(_expense, [
      _debt('chloe', 4000),
      _debt('bob', 600, credits: 340),
    ]);

    expect(shares.map((s) => s.uid), ['amara', 'bob', 'chloe']);
    expect(shares.first.payment, SharePayment.payer);
    expect(shares.first.amount, 4000);
  });

  test('a share includes the credits used on it', () {
    final bob = ExpenseShares.from(_expense, [
      _debt('bob', 600, credits: 340),
    ]).firstWhere((s) => s.uid == 'bob');

    expect(bob.amount, 4000); // 600 + 340 credits x 10
    expect(bob.amountDue, 600);
    expect(bob.creditsApplied, 340);
    expect(bob.payment, SharePayment.pending);
  });

  test('payment states: pending, paid with a method, covered by credits', () {
    final shares = ExpenseShares.from(_expense, [
      _debt('bob', 4000),
      _debt(
        'chloe',
        4000,
        status: DebtStatus.settled,
        method: SettlementMethod.cash,
      ),
      _debt(
        'dan',
        0,
        credits: 400,
        status: DebtStatus.settled,
        method: SettlementMethod.credits,
      ),
    ]);

    SharePayment of(String uid) =>
        shares.firstWhere((s) => s.uid == uid).payment;

    expect(of('bob'), SharePayment.pending);
    expect(of('chloe'), SharePayment.paid);
    expect(of('dan'), SharePayment.coveredByCredits);
    expect(
      shares.firstWhere((s) => s.uid == 'chloe').method,
      SettlementMethod.cash,
    );
  });

  test('paidCount counts only debts settled with real money', () {
    final count = ExpenseShares.paidCount([
      _debt(
        'bob',
        4000,
        status: DebtStatus.settled,
        method: SettlementMethod.momo,
      ),
      _debt('chloe', 0, status: DebtStatus.settled),
      _debt('dan', 4000),
    ]);

    expect(count, 1);
  });

  test('with no debts the payer carries the whole total', () {
    final shares = ExpenseShares.from(_expense, const []);

    expect(shares, hasLength(1));
    expect(shares.single.amount, 12000);
  });
}
