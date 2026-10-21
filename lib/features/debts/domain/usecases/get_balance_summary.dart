// Owner: D - Person D (Debts, Settling, Nudges, Notifications, Release Build)
// Description: UseCase: Calculate net balance summary

// TODO(D): Implement GetBalanceSummary according to project specification

import '../entities/balance_summary.dart';
import '../repositories/debt_repository.dart';

class GetBalanceSummary {
  final DebtRepository repository;

  const GetBalanceSummary(this.repository);

  Stream<BalanceSummary> call({
    required String householdId,
    required String meUid,
  }) {
    // D3: map pending debts through BalanceCalculator.
    throw UnimplementedError('Implemented with D3 balance calculation.');
  }
}