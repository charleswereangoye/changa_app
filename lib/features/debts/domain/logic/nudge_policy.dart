// Checks whether a nudge is allowed without depending on Firebase.

import '../../../../core/error/failures.dart';
import 'settlement_plan.dart';

class NudgePolicy {
  const NudgePolicy({required this.cooldown});

  final Duration cooldown;

  /// Returns null when allowed, otherwise a friendly failure.
  /// Build [balance] with the sender as meUid and recipient as otherUid.
  /// Pass the latest nudge time for this sender-recipient pair.
  Failure? check({
    required SettlementPlan balance,
    required DateTime now,
    DateTime? lastNudgedAt,
  }) {
    if (cooldown.inMicroseconds <= 0) {
      throw ArgumentError.value(
        cooldown,
        'cooldown',
        'The nudge cooldown must be positive.',
      );
    }

    if (balance.netAmount <= 0) {
      return const ValidationFailure(
        'You can send a reminder when this housemate owes you a balance.',
      );
    }

    if (lastNudgedAt != null && now.difference(lastNudgedAt) < cooldown) {
      return const NudgeCooldownFailure();
    }

    return null;
  }
}
