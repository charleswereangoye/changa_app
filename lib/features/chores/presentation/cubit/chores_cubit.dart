import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:changa_app/core/error/failures.dart';
import 'package:changa_app/core/utils/date_helpers.dart';
import 'package:changa_app/features/chores/domain/entities/chore.dart';
import 'package:changa_app/features/chores/domain/usecases/complete_chore.dart';
import 'package:changa_app/features/chores/domain/usecases/watch_chores_for_day.dart';

part 'chores_state.dart';

/// Drives the Chore Roster: which day is open, its chores, and ticking.
class ChoresCubit extends Cubit<ChoresState> {
  ChoresCubit({
    required this._watchChoresForDay,
    required this._completeChore,
    required this.householdId,
    required this.meUid,
    DateTime Function()? clock,
  }) : super(_firstState((clock ?? DateTime.now)()));

  final WatchChoresForDay _watchChoresForDay;
  final CompleteChore _completeChore;
  final String householdId;
  final String meUid;

  StreamSubscription<List<Chore>>? _subscription;
  int _generation = 0;
  int _noticeId = 0;

  static ChoresState _firstState(DateTime now) {
    final today = DateHelpers.startOfDay(now);
    return ChoresState(today: today, selectedDay: today);
  }

  void load() => _watch(state.selectedDay);

  void retry() => _watch(state.selectedDay);

  void selectDay(DateTime day) {
    final selected = DateHelpers.startOfDay(day);
    if (_subscription != null &&
        DateHelpers.isSameDay(selected, state.selectedDay)) {
      return;
    }
    emit(
      state.copyWith(
        selectedDay: selected,
        status: ChoresStatus.loading,
        chores: const [],
      ),
    );
    _watch(selected);
  }

  Future<void> completeChore(String choreId) async {
    final chore = state.chores.where((c) => c.id == choreId).firstOrNull;
    if (chore == null || chore.isDone || chore.assignedToUid != meUid) return;
    if (state.completingIds.contains(choreId)) return;

    emit(state.copyWith(completingIds: {...state.completingIds, choreId}));

    final result = await _completeChore(householdId, choreId);
    if (isClosed) return;

    final failure = result.failureOrNull;
    emit(
      state.copyWith(
        completingIds: {...state.completingIds}..remove(choreId),
        notice: ChoreNotice(
          ++_noticeId,
          failure == null
              ? 'Nice work! +${chore.difficulty.credits} pts'
              : failure.message,
          isError: failure != null,
        ),
      ),
    );
  }

  void clearNotice() => emit(state.copyWith(clearNotice: true));

  void _watch(DateTime day) {
    final generation = ++_generation;
    _subscription?.cancel();
    emit(state.copyWith(status: ChoresStatus.loading, clearFailure: true));

    _subscription = _watchChoresForDay(householdId, day).listen(
      (chores) {
        if (isClosed || generation != _generation) return;
        emit(
          state.copyWith(
            status: ChoresStatus.loaded,
            chores: _sorted(chores),
            clearFailure: true,
          ),
        );
      },
      onError: (Object error) {
        if (isClosed || generation != _generation) return;
        emit(
          state.copyWith(
            status: ChoresStatus.failure,
            failure: const UnknownFailure(
              'We couldn’t load the chores. Please try again.',
            ),
          ),
        );
      },
    );
  }

  /// Open chores first, finished ones last, then alphabetical.
  List<Chore> _sorted(List<Chore> chores) {
    final sorted = [...chores]
      ..sort((a, b) {
        if (a.isDone != b.isDone) return a.isDone ? 1 : -1;
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });
    return sorted;
  }

  @override
  Future<void> close() async {
    _generation++;
    await _subscription?.cancel();
    _subscription = null;
    return super.close();
  }
}
