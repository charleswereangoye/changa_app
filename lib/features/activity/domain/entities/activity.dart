import 'package:equatable/equatable.dart';

enum ActivityType {
  expenseAdded,
  expenseDeleted,
  debtSettled,
  choreCompleted,
  memberJoined,
  memberRemoved,
  swapRequested,
  swapAccepted,
  nudgeSent,
}

class Activity extends Equatable {
  final String id;
  final ActivityType type;
  final String actorUid;
  final String? targetUid;
  final String? refId;
  final int? amount;
  final DateTime createdAt;

  const Activity({
    required this.id,
    required this.type,
    required this.actorUid,
    this.targetUid,
    this.refId,
    this.amount,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    type,
    actorUid,
    targetUid,
    refId,
    amount,
    createdAt,
  ];
}
