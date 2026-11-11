// Owner: C - Person C (Expenses, Dashboard, Documentation)
// Description: Works out each person's share of an expense and who has paid

import 'package:equatable/equatable.dart';

import 'package:changa_app/core/enums/settlement_method.dart';
import 'package:changa_app/features/debts/domain/entities/debt.dart';
import 'package:changa_app/features/debts/domain/entities/debt_status.dart';
import 'package:changa_app/features/expenses/domain/entities/expense.dart';
import 'package:changa_app/features/expenses/domain/logic/apply_credits.dart';

enum SharePayment { payer, pending, paid, coveredByCredits }

class ExpenseShare extends Equatable {
  const ExpenseShare({
    required this.uid,
    required this.amount,
    required this.payment,
    this.creditsApplied = 0,
    this.amountDue = 0,
    this.method,
  });

  final String uid;

  /// The whole share in RWF, credits included.
  final int amount;
  final SharePayment payment;

  /// Credits used on this share (points, not RWF).
  final int creditsApplied;

  /// RWF still to pay after credits.
  final int amountDue;
  final SettlementMethod? method;

  @override
  List<Object?> get props => [
    uid,
    amount,
    payment,
    creditsApplied,
    amountDue,
    method,
  ];
}

abstract final class ExpenseShares {
  /// The payer first, then everyone who owes, ordered by uid.
  ///
  /// The payer has no debt, so their share is what is left of the total
  /// after everyone else's share (credits included).
  static List<ExpenseShare> from(Expense expense, List<Debt> debts) {
    final rows = <ExpenseShare>[];
    var debtorsTotal = 0;

    for (final debt in debts) {
      if (debt.debtorUid == expense.paidByUid) continue;
      final full = debt.amount + debt.creditsApplied * rwfPerCredit;
      debtorsTotal += full;
      rows.add(
        ExpenseShare(
          uid: debt.debtorUid,
          amount: full,
          creditsApplied: debt.creditsApplied,
          amountDue: debt.amount,
          payment: _paymentOf(debt),
          method: debt.settlementMethod,
        ),
      );
    }
    rows.sort((a, b) => a.uid.compareTo(b.uid));

    final left = expense.totalAmount - debtorsTotal;
    return [
      ExpenseShare(
        uid: expense.paidByUid,
        amount: left < 0 ? 0 : left,
        payment: SharePayment.payer,
      ),
      ...rows,
    ];
  }

  /// How many debts were already paid with real money. Same rule as the
  /// data-layer guard: settled and more than 0 RWF.
  static int paidCount(List<Debt> debts) =>
      debts.where((d) => d.status == DebtStatus.settled && d.amount > 0).length;

  static SharePayment _paymentOf(Debt debt) {
    if (debt.status != DebtStatus.settled) return SharePayment.pending;
    if (debt.amount == 0 || debt.settlementMethod == SettlementMethod.credits) {
      return SharePayment.coveredByCredits;
    }
    return SharePayment.paid;
  }
}
