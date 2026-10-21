// Owner: D - Person D (Debts, Settling, Nudges, Notifications, Release Build)
// Description: UseCase: Stream debts between two specific members

// TODO(D): Implement WatchDebtsBetween according to project specification

import '../entities/debt.dart';
import '../repositories/debt_repository.dart';

class WatchDebtsBetween {
  final DebtRepository repository;

  const WatchDebtsBetween(this.repository);

  Stream<List<Debt>> call(
    String householdId,
    String uidA,
    String uidB,
  ) {
    return repository.watchDebtsBetween(householdId, uidA, uidB);
  }
}