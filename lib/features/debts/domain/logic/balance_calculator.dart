import '../entities/balance_summary.dart';
import '../entities/debt.dart';
import '../entities/debt_status.dart';

class BalanceCalculator {
  const BalanceCalculator();

  /// Positive member balance: they owe me.
  /// Negative member balance: I owe them.
  BalanceSummary summarize({
    required Iterable<Debt> pendingDebts,
    required String meUid,
  }) {
    final byMember = <String, int>{};

    for (final debt in pendingDebts) {
      if (debt.status != DebtStatus.pending) {
        continue;
      }

      if (debt.debtorUid == debt.creditorUid) {
        continue;
      }

      if (debt.creditorUid == meUid) {
        byMember.update(
          debt.debtorUid,
          (balance) => balance + debt.amount,
          ifAbsent: () => debt.amount,
        );
      } else if (debt.debtorUid == meUid) {
        byMember.update(
          debt.creditorUid,
          (balance) => balance - debt.amount,
          ifAbsent: () => -debt.amount,
        );
      }
    }

    var youAreOwed = 0;
    var youOwe = 0;

    for (final balance in byMember.values) {
      if (balance > 0) {
        youAreOwed += balance;
      } else if (balance < 0) {
        youOwe += -balance;
      }
    }

    return BalanceSummary(
      youAreOwed: youAreOwed,
      youOwe: youOwe,
      net: youAreOwed - youOwe,
      byMember: byMember,
    );
  }
}
