// Selects pending debts between two members and calculates their net amount.

import '../entities/debt.dart';
import '../entities/debt_status.dart';

class SettlementPlan {
  SettlementPlan._({required List<String> debtIds, required this.netAmount})
    : debtIds = List<String>.unmodifiable(debtIds);

  /// Every pending debt between the pair, in both directions.
  final List<String> debtIds;

  /// Positive: the other person owes me.
  /// Negative: I owe the other person.
  final int netAmount;

  /// The whole-RWF amount represented by this settlement.
  int get amount => netAmount.abs();

  bool get isEmpty => debtIds.isEmpty;

  factory SettlementPlan.between({
    required Iterable<Debt> debts,
    required String meUid,
    required String otherUid,
  }) {
    if (meUid.isEmpty || otherUid.isEmpty || meUid == otherUid) {
      throw ArgumentError(
        'Settlement requires two different, non-empty member IDs.',
      );
    }

    final debtIds = <String>[];
    final seenIds = <String>{};
    var netAmount = 0;

    for (final debt in debts) {
      if (debt.status != DebtStatus.pending) {
        continue;
      }

      final owedToMe = debt.fromUid == otherUid && debt.toUid == meUid;
      final owedByMe = debt.fromUid == meUid && debt.toUid == otherUid;

      if (!owedToMe && !owedByMe) {
        continue;
      }

      // Avoid counting the same document more than once.
      if (!seenIds.add(debt.id)) {
        continue;
      }

      final amount = debt.amount;

      if (!amount.isFinite ||
          amount < 0 ||
          amount != amount.truncateToDouble()) {
        throw FormatException(
          'Debt ${debt.id} must have a finite, non-negative whole RWF amount.',
        );
      }

      final wholeAmount = amount.toInt();

      debtIds.add(debt.id);
      netAmount += owedToMe ? wholeAmount : -wholeAmount;
    }

    return SettlementPlan._(debtIds: debtIds, netAmount: netAmount);
  }
}
