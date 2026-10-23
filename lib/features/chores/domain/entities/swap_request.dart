import 'package:equatable/equatable.dart';

enum SwapStatus { pending, accepted, declined, cancelled }

class SwapRequest extends Equatable {
  const SwapRequest({
    required this.id,
    required this.choreId,
    required this.fromUid,
    required this.toUid,
    required this.status,
    required this.createdAt,
    this.note,
  });

  final String id;
  final String choreId;
  final String fromUid;
  final String toUid;
  final String? note;
  final SwapStatus status;
  final DateTime createdAt;

  bool get isPending => status == SwapStatus.pending;

  @override
  List<Object?> get props => [
    id,
    choreId,
    fromUid,
    toUid,
    note,
    status,
    createdAt,
  ];
}
