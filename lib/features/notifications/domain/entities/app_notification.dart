import 'package:equatable/equatable.dart';

class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.recipientUid,
    required this.actorUid,
    required this.type,
    required this.title,
    required this.body,
    required this.read,
    required this.createdAt,
    this.refId,
  });

  final String id;

  /// The member who receives the notification.
  final String recipientUid;

  /// The member whose action created it.
  final String actorUid;

  /// newExpense, nudge, settled, swapRequest, or swapResponse.
  final String type;

  final String title;
  final String body;

  /// Related expense, chore, or member ID, depending on the type.
  final String? refId;

  final bool read;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
    id,
    recipientUid,
    actorUid,
    type,
    title,
    body,
    refId,
    read,
    createdAt,
  ];
}
