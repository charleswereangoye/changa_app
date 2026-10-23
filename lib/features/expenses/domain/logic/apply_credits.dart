// Owner: C - Person C (Expenses, Dashboard, Documentation)
// Description: Applies a housemate's chore credits to their share of an expense

import 'dart:math' as math;

/// 1 credit = 10 RWF (100 credits = 1,000 RWF).
// TODO(C): move to AppConstants once A has pushed app_constants.dart.
const int _rwfPerCredit = 10;

abstract final class ApplyCredits {
  /// Uses as many credits as possible without paying more than the share.
  /// Only whole credits are used, so a leftover under 10 RWF is still owed.
  static ({int amountDue, int creditsUsed}) apply({
    required int share,
    required int creditBalance,
  }) {
    final maxUsable = share ~/ _rwfPerCredit;
    final creditsUsed = math.max(0, math.min(creditBalance, maxUsable));
    final amountDue = share - creditsUsed * _rwfPerCredit;
    return (amountDue: amountDue, creditsUsed: creditsUsed);
  }
}
