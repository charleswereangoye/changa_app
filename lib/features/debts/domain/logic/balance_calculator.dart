// Calculates per-member net balances in whole RWF.

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

      // Self-debts do not contribute to a balance.
      if (debt.fromUid == debt.toUid) {
        continue;
      }

      // Ignore debts between other housemates.
      if (debt.fromUid != meUid && debt.toUid != meUid) {
        continue;
      }

      final amount = _wholeRwf(debt);

      if (debt.toUid == meUid) {
        byMember.update(
          debt.fromUid,
          (balance) => balance + amount,
          ifAbsent: () => amount,
        );
      } else {
        byMember.update(
          debt.toUid,
          (balance) => balance - amount,
          ifAbsent: () => -amount,
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

  /// The shared entity currently stores a double, but RWF must be whole.
  /// Reject invalid amounts instead of silently rounding or truncating.
  int _wholeRwf(Debt debt) {
    final amount = debt.amount;

    if (!amount.isFinite || amount < 0 || amount != amount.truncateToDouble()) {
      throw FormatException(
        'Debt ${debt.id} must have a finite, non-negative whole RWF amount.',
      );
    }

    return amount.toInt();
  }
}
