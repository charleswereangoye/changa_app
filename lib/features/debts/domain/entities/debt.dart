// Owner: D - Person D (Debts, Settling, Nudges, Notifications, Release Build)
// Description: Debt domain entity

// TODO(D): Implement Debt according to project specification

class Debt {
  final String id;
  final String expenseId;
  final String debtorUid;
  final String creditorUid;
  final int amount;
  final int creditsApplied;
  final String status;
  final String? settlementMethod;
  final DateTime? settledAt;
  final DateTime createdAt;

  const Debt({
    required this.id,
    required this.expenseId,
    required this.debtorUid,
    required this.creditorUid,
    required this.amount,
    required this.creditsApplied,
    required this.status,
    required this.createdAt,
    this.settlementMethod,
    this.settledAt,
  });

  bool get isPending => status == 'pending';

  bool get isSettled => status == 'settled';
}
