import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:changa_app/core/utils/date_helpers.dart';
import 'package:changa_app/features/chores/domain/entities/chore.dart';
import 'package:changa_app/features/chores/domain/usecases/complete_chore.dart';
import 'package:changa_app/features/chores/domain/usecases/watch_all_chores.dart';

part 'missed_chore_state.dart';

/// Looks for chores of mine that slipped past their day and asks about them
/// once, the first time the roster opens.
class MissedChoreCubit extends Cubit<MissedChoreState> {
  MissedChoreCubit({
    required this._watchAllChores,
    required this._completeChore,
    required this.householdId,
    required this.meUid,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       super(const MissedChoreState());

  final WatchAllChores _watchAllChores;
  final CompleteChore _completeChore;
  final String householdId;
  final String meUid;
  final DateTime Function() _clock;

  StreamSubscription<List<Chore>>? _subscription;
  bool _asked = false;
  int _noticeId = 0;

  void start() {
    _subscription?.cancel();
    _subscription = _watchAllChores(householdId).listen(
      _onChores,
      // No reminder is better than an error popup nobody asked for.
      onError: (_) {},
    );
  }

  void _onChores(List<Chore> chores) {
    if (isClosed || _asked) return;

    final now = _clock();
    final missed =
        chores
            .where(
              (c) => c.assignedToUid == meUid && DateHelpers.isMissed(c, now),
            )
            .toList()
          ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    if (missed.isEmpty) return;

    _asked = true;
    emit(state.copyWith(prompt: missed.first, otherCount: missed.length - 1));
  }

  /// "Dismiss": leave it, no more reminders this session.
  void dismiss() => emit(state.copyWith(clearPrompt: true));

  Future<void> completePrompt() async {
    final chore = state.prompt;
    if (chore == null) return;
    emit(state.copyWith(clearPrompt: true));

    final result = await _completeChore(householdId, chore.id);

    if (isClosed) return;
    emit(
      state.copyWith(
        notice: result.isSuccess
            ? MissedNotice(
                ++_noticeId,
                'Nice work! +${chore.difficulty.credits} pts',
              )
            : MissedNotice(
                ++_noticeId,
                result.failureOrNull?.message ??
                    'Couldn’t finish the chore. Please try again.',
                isError: true,
              ),
      ),
    );
  }

  void clearNotice() => emit(state.copyWith(clearNotice: true));

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
