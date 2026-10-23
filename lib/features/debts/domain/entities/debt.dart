import 'package:equatable/equatable.dart';
import 'package:changa_app/core/enums/settlement_method.dart';

import 'debt_status.dart';

class Debt extends Equatable {
  const Debt({
    required this.id,
    required this.householdId,
    required this.fromUid,
    required this.toUid,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.settledAt,
    this.settledMethod,
  });

  final String id;
  final String householdId;
  final String fromUid;
  final String toUid;
  final double amount;
  final DebtStatus status;
  final DateTime createdAt;
  final DateTime? settledAt;
  final SettlementMethod? settledMethod;

  @override
  List<Object?> get props => [
    id,
    householdId,
    fromUid,
    toUid,
    amount,
    status,
    createdAt,
    settledAt,
    settledMethod,
  ];
}
