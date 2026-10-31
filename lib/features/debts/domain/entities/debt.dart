import 'package:changa_app/core/enums/settlement_method.dart';
import 'package:equatable/equatable.dart';

import 'debt_status.dart';

class Debt extends Equatable {
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

  final String id;

  /// The expense that created this debt.
  final String expenseId;

  /// The person who owes money.
  final String debtorUid;

  /// The person who paid the expense.
  final String creditorUid;

  /// Whole RWF remaining after credits were applied.
  final int amount;

  /// Number of house credits used, not their RWF value.
  final int creditsApplied;

  final DebtStatus status;
  final SettlementMethod? settlementMethod;
  final DateTime? settledAt;
  final DateTime createdAt;

  bool get isPending => status == DebtStatus.pending;

  bool get isSettled => status == DebtStatus.settled;

  @override
  List<Object?> get props => [
    id,
    expenseId,
    debtorUid,
    creditorUid,
    amount,
    creditsApplied,
    status,
    settlementMethod,
    settledAt,
    createdAt,
  ];
}
