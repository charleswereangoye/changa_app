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

      final owedToMe = debt.debtorUid == otherUid && debt.creditorUid == meUid;
      final owedByMe = debt.debtorUid == meUid && debt.creditorUid == otherUid;

      if (!owedToMe && !owedByMe) {
        continue;
      }

      if (!seenIds.add(debt.id)) {
        continue;
      }

      debtIds.add(debt.id);
      netAmount += owedToMe ? debt.amount : -debt.amount;
    }

    return SettlementPlan._(debtIds: debtIds, netAmount: netAmount);
  }
}
