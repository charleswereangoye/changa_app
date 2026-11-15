part of 'swap_cubit.dart';

enum SwapFormStatus { idle, sending, sent, failure }

/// A housemate the chore can be offered to.
class SwapCandidate extends Equatable {
  const SwapCandidate({required this.uid, required this.name});

  final String uid;
  final String name;

  @override
  List<Object?> get props => [uid, name];
}

class SwapState extends Equatable {
  const SwapState({
    required this.candidates,
    this.weekCounts = const {},
    this.note = '',
    this.status = SwapFormStatus.idle,
    this.sendingUid,
    this.message,
  });

  final List<SwapCandidate> candidates;

  /// Open chores due this week, per housemate.
  final Map<String, int> weekCounts;
  final String note;
  final SwapFormStatus status;
  final String? sendingUid;

  /// What to tell the user once a request is sent or has failed.
  final String? message;

  bool get isSending => status == SwapFormStatus.sending;

  int countFor(String uid) => weekCounts[uid] ?? 0;

  SwapState copyWith({
    Map<String, int>? weekCounts,
    String? note,
    SwapFormStatus? status,
    String? sendingUid,
    String? message,
    bool clearSending = false,
    bool clearMessage = false,
  }) {
    return SwapState(
      candidates: candidates,
      weekCounts: weekCounts ?? this.weekCounts,
      note: note ?? this.note,
      status: status ?? this.status,
      sendingUid: clearSending ? null : (sendingUid ?? this.sendingUid),
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [
    candidates,
    weekCounts,
    note,
    status,
    sendingUid,
    message,
  ];
}
