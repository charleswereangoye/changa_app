// Owner: D - Person D (Debts, Settling, Nudges, Notifications, Release Build)
// Description: UseCase: Stream debts since date for Harmony Score calculation

// TODO(D): Implement WatchDebtsSince according to project specification

import '../entities/debt.dart';
import '../repositories/debt_repository.dart';

class WatchDebtsSince {
  final DebtRepository repository;

  const WatchDebtsSince(this.repository);

  Stream<List<Debt>> call(
    String householdId,
    DateTime since,
  ) {
    return repository.watchDebtsSince(householdId, since);
  }
}