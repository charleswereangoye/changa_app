part of 'missed_chore_cubit.dart';

class MissedNotice extends Equatable {
  const MissedNotice(this.id, this.text, {this.isError = false});

  final int id;
  final String text;
  final bool isError;

  @override
  List<Object?> get props => [id, text, isError];
}

class MissedChoreState extends Equatable {
  const MissedChoreState({this.prompt, this.otherCount = 0, this.notice});

  /// The chore to remind the user about. Null once dealt with, and it is
  /// only ever set once per session.
  final Chore? prompt;

  /// How many other missed chores are waiting.
  final int otherCount;
  final MissedNotice? notice;

  MissedChoreState copyWith({
    Chore? prompt,
    int? otherCount,
    MissedNotice? notice,
    bool clearPrompt = false,
    bool clearNotice = false,
  }) {
    return MissedChoreState(
      prompt: clearPrompt ? null : (prompt ?? this.prompt),
      otherCount: otherCount ?? this.otherCount,
      notice: clearNotice ? null : (notice ?? this.notice),
    );
  }

  @override
  List<Object?> get props => [prompt, otherCount, notice];
}
