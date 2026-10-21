// Owner: D - Person D (Debts, Settling, Nudges, Notifications, Release Build)
// Description: DebtRepository domain interface

// TODO(D): Implement DebtRepository according to project specification

import '../../../../core/error/result.dart';
import '../entities/debt.dart';

abstract class DebtRepository {
  Stream<List<Debt>> watchPendingDebts(String householdId);

  // Includes settled debts: the Harmony calculator needs them.
  Stream<List<Debt>> watchDebtsSince(String householdId, DateTime since);

  Stream<List<Debt>> watchDebtsBetween(
    String householdId,
    String uidA,
    String uidB,
  );

  Future<Result<void>> settleBetween({
    required String householdId,
    required String meUid,
    required String otherUid,
    required String method,
  });

  Future<Result<void>> sendNudge({
    required String householdId,
    required String fromUid,
    required String toUid,
  });
}
