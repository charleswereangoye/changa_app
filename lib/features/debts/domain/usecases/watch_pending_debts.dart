// Owner: D - Person D (Debts, Settling, Nudges, Notifications, Release Build)
// Description: UseCase: Stream pending debts for household

// TODO(D): Implement WatchPendingDebts according to project specification

import '../entities/debt.dart';
import '../repositories/debt_repository.dart';

class WatchPendingDebts {
  final DebtRepository repository;

  const WatchPendingDebts(this.repository);

  Stream<List<Debt>> call(String householdId) {
    return repository.watchPendingDebts(householdId);
  }
}