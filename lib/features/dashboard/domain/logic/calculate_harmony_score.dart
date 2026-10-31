import 'package:changa_app/features/debts/domain/entities/debt.dart';
import 'package:changa_app/features/debts/domain/entities/debt_status.dart';
import 'package:changa_app/core/enums/settlement_method.dart';
import 'package:changa_app/core/constants/app_constants.dart';
import 'package:changa_app/core/utils/date_helpers.dart';
import 'package:changa_app/features/chores/domain/entities/chore.dart';
import 'package:changa_app/features/dashboard/domain/entities/harmony_score.dart';

/// Household health from chores done on time and debts settled promptly.
/// Returns null when there is nothing to judge yet (the dashboard shows "—").
class CalculateHarmonyScore {
  const CalculateHarmonyScore();

  HarmonyScore? call({
    required List<Chore> chores,
    required List<Debt> debts,
    required DateTime now,
  }) {
    final choreScore = _choreScore(chores, now);
    final paymentScore = _paymentScore(debts, now);
    if (choreScore == null && paymentScore == null) return null;

    // If only one side has data, that side speaks for the whole house.
    final value = switch ((choreScore, paymentScore)) {
      (final c?, null) => c,
      (null, final p?) => p,
      (final c?, final p?) =>
        (AppConstants.harmonyChoreWeight * c +
                AppConstants.harmonyPaymentWeight * p)
            .round(),
      _ => 0,
    };

    return HarmonyScore(
      value: value,
      tier: HarmonyTier.fromValue(value),
      choreScore: choreScore,
      paymentScore: paymentScore,
    );
  }

  int? _choreScore(List<Chore> chores, DateTime now) {
    final today = DateHelpers.startOfDay(now);
    final windowStart = DateHelpers.addDays(
      today,
      -AppConstants.harmonyChoreWindowDays,
    );

    var due = 0;
    var onTime = 0;
    for (final chore in chores) {
      final dueDay = DateHelpers.startOfDay(chore.dueDate);
      if (dueDay.isBefore(windowStart) || dueDay.isAfter(today)) continue;

      // Due today and still open: the day is not over, so it is not a miss.
      if (chore.status == ChoreStatus.pending && !dueDay.isBefore(today)) {
        continue;
      }

      due++;
      if (_doneOnTime(chore, dueDay)) onTime++;
    }
    return due == 0 ? null : _percent(onTime, due);
  }

  bool _doneOnTime(Chore chore, DateTime dueDay) {
    final completedAt = chore.completedAt;
    if (chore.status != ChoreStatus.done || completedAt == null) return false;
    return !DateHelpers.startOfDay(completedAt).isAfter(dueDay);
  }

  int? _paymentScore(List<Debt> debts, DateTime now) {
    final windowStart = now.subtract(
      const Duration(days: AppConstants.harmonyDebtWindowDays),
    );
    const settleWindow = Duration(days: AppConstants.harmonySettleWindowDays);

    var total = 0;
    var healthy = 0;
    for (final debt in debts) {
      // Old settled debts leave the window, but unpaid debts still count.
      if (debt.createdAt.isBefore(windowStart) &&
          debt.status == DebtStatus.settled) {
        continue;
      }
      total++;
      if (_isHealthy(debt, now, settleWindow)) healthy++;
    }
    return total == 0 ? null : _percent(healthy, total);
  }

  bool _isHealthy(Debt debt, DateTime now, Duration settleWindow) {
    if (debt.status == DebtStatus.settled) {
      // Paid for by chore credits from the start, so it was never late.
      if (debt.settlementMethod == SettlementMethod.credits) return true;
      final settledAt = debt.settledAt;
      return settledAt == null ||
          settledAt.difference(debt.createdAt) <= settleWindow;
    }
    return now.difference(debt.createdAt) < settleWindow;
  }

  int _percent(int part, int whole) => (100 * part / whole).round();
}
