// Owner: D - Person D (Debts, Settling, Nudges, Notifications, Release Build)
// Description: UseCase: Send friendly payment reminder with 24h cooldown

// TODO(D): Implement SendNudge according to project specification

import 'package:changa_app/core/error/result.dart';

import '../repositories/debt_repository.dart';

class SendNudge {
  final DebtRepository repository;

  const SendNudge(this.repository);

  Future<Result<void>> call({
    required String householdId,
    required String fromUid,
    required String toUid,
  }) {
    return repository.sendNudge(
      householdId: householdId,
      fromUid: fromUid,
      toUid: toUid,
    );
  }
}
