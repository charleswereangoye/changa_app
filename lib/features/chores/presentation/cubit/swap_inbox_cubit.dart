import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:changa_app/features/chores/domain/entities/chore.dart';
import 'package:changa_app/features/chores/domain/entities/swap_request.dart';
import 'package:changa_app/features/chores/domain/usecases/respond_to_swap.dart';
import 'package:changa_app/features/chores/domain/usecases/watch_all_chores.dart';
import 'package:changa_app/features/chores/domain/usecases/watch_swap_requests.dart';

part 'swap_inbox_state.dart';

/// Swap requests other housemates have sent me, with accept and decline.
class SwapInboxCubit extends Cubit<SwapInboxState> {
  SwapInboxCubit({
    required this._watchSwapRequests,
    required this._watchAllChores,
    required this._respondToSwap,
    required this.householdId,
    required this.meUid,
  }) : super(const SwapInboxState());

  final WatchSwapRequests _watchSwapRequests;
  final WatchAllChores _watchAllChores;
  final RespondToSwap _respondToSwap;
  final String householdId;
  final String meUid;

  StreamSubscription<List<SwapRequest>>? _requests;
  StreamSubscription<List<Chore>>? _chores;
  int _noticeId = 0;

  void start() {
    _requests?.cancel();
    _chores?.cancel();

    // A failed stream just means no banner; the roster itself still works.
    _requests = _watchSwapRequests(householdId, meUid).listen((requests) {
      if (isClosed) return;
      emit(state.copyWith(requests: requests));
    }, onError: (_) {});

    _chores = _watchAllChores(householdId).listen((chores) {
      if (isClosed) return;
      emit(
        state.copyWith(choreTitles: {for (final c in chores) c.id: c.title}),
      );
    }, onError: (_) {});
  }

  Future<void> respond(String requestId, {required bool accept}) async {
    if (state.respondingIds.contains(requestId)) return;
    if (!state.requests.any((r) => r.id == requestId)) return;

    emit(state.copyWith(respondingIds: {...state.respondingIds, requestId}));

    final result = await _respondToSwap(
      householdId: householdId,
      requestId: requestId,
      accept: accept,
    );

    if (isClosed) return;
    final remaining = {...state.respondingIds}..remove(requestId);
    final notice = result.isSuccess
        ? InboxNotice(
            ++_noticeId,
            accept
                ? 'Swap accepted. The chore is now yours.'
                : 'Swap declined.',
          )
        : InboxNotice(
            ++_noticeId,
            result.failureOrNull?.message ??
                'Couldn’t answer the request. Please try again.',
            isError: true,
          );
    emit(state.copyWith(respondingIds: remaining, notice: notice));
  }

  void clearNotice() => emit(state.copyWith(clearNotice: true));

  @override
  Future<void> close() async {
    await _requests?.cancel();
    await _chores?.cancel();
    return super.close();
  }
}
