// Owner: D - Person D (Debts, Settling, Nudges, Notifications, Release Build)
// Description: UseCase: Mark all debts between two members as settled

// TODO(D): Implement SettleBetween according to project specification

import '../../../../core/error/result.dart';
import '../repositories/debt_repository.dart';

class SettleBetween {
  final DebtRepository repository;

  const SettleBetween(this.repository);

  Future<Result<void>> call({
    required String householdId,
    required String meUid,
    required String otherUid,
    required String method,
  }) {
    return repository.settleBetween(
      householdId: householdId,
      meUid: meUid,
      otherUid: otherUid,
      method: method,
    );
  }
}
