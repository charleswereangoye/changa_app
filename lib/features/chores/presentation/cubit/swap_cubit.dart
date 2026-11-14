import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:changa_app/core/utils/date_helpers.dart';
import 'package:changa_app/features/chores/domain/entities/chore.dart';
import 'package:changa_app/features/chores/domain/usecases/request_swap.dart';
import 'package:changa_app/features/chores/domain/usecases/watch_all_chores.dart';

part 'swap_state.dart';

/// Runs the "Swap this chore" sheet: shows how busy each housemate is this
/// week and sends the request to the one you pick.
class SwapCubit extends Cubit<SwapState> {
  SwapCubit({
    required this._requestSwap,
    required this._watchAllChores,
    required this.householdId,
    required this.chore,
    required List<SwapCandidate> candidates,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       super(SwapState(candidates: candidates));

  static const maxNoteLength = 120;

  final RequestSwap _requestSwap;
  final WatchAllChores _watchAllChores;
  final String householdId;
  final Chore chore;
  final DateTime Function() _clock;

  StreamSubscription<List<Chore>>? _subscription;

  /// Starts counting each housemate's chores for the week.
  void load() {
    _subscription?.cancel();
    _subscription = _watchAllChores(householdId).listen(
      _onChores,
      // The counts are a nicety; the sheet still works without them.
      onError: (_) {},
    );
  }

  void _onChores(List<Chore> chores) {
    if (isClosed) return;
    final week = DateHelpers.weekDays(_clock());
    final start = week.first;
    final end = DateHelpers.addDays(week.last, 1);

    final counts = <String, int>{};
    for (final c in chores) {
      final due = DateHelpers.startOfDay(c.dueDate);
      if (c.isDone || due.isBefore(start) || !due.isBefore(end)) continue;
      counts.update(c.assignedToUid, (n) => n + 1, ifAbsent: () => 1);
    }
    emit(state.copyWith(weekCounts: counts));
  }

  void noteChanged(String value) => emit(state.copyWith(note: value));

  Future<void> request(String toUid) async {
    if (state.isSending) return;
    final target = state.candidates.where((c) => c.uid == toUid);
    if (target.isEmpty) return;

    emit(
      state.copyWith(
        status: SwapFormStatus.sending,
        sendingUid: toUid,
        clearMessage: true,
      ),
    );

    final note = state.note.trim();
    final result = await _requestSwap(
      householdId: householdId,
      choreId: chore.id,
      toUid: toUid,
      note: note.isEmpty ? null : note,
    );

    if (isClosed) return;
    if (result.isSuccess) {
      emit(
        state.copyWith(
          status: SwapFormStatus.sent,
          clearSending: true,
          message: 'Swap request sent to ${target.first.name}.',
        ),
      );
    } else {
      emit(
        state.copyWith(
          status: SwapFormStatus.failure,
          clearSending: true,
          message:
              result.failureOrNull?.message ??
              'Couldn’t send the request. Please try again.',
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
