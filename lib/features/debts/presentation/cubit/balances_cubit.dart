import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/balance_summary.dart';
import '../../domain/usecases/get_balance_summary.dart';

part 'balances_state.dart';

class BalancesCubit extends Cubit<BalancesState> {
  BalancesCubit(this._getBalanceSummary) : super(const BalancesStateInitial());

  final GetBalanceSummary _getBalanceSummary;

  StreamSubscription<BalanceSummary>? _subscription;
  String? _householdId;
  String? _uid;
  int _session = 0;

  /// Pass null IDs when signing out or leaving a household.
  Future<void> start({
    required String? householdId,
    required String? uid,
    bool force = false,
  }) async {
    if (isClosed) return;

    final nextHousehold = householdId == null || householdId.isEmpty
        ? null
        : householdId;
    final nextUid = uid == null || uid.isEmpty ? null : uid;

    if (!force &&
        nextHousehold == _householdId &&
        nextUid == _uid &&
        _subscription != null) {
      return;
    }

    final version = ++_session;
    _householdId = nextHousehold;
    _uid = nextUid;

    final previous = _subscription;
    _subscription = null;

    // Clear the previous session's balances immediately.
    if (nextHousehold == null || nextUid == null) {
      emit(const BalancesStateInitial());
    } else {
      emit(const BalancesStateLoading());
    }

    await previous?.cancel();
    if (!_isCurrent(version)) return;
    if (nextHousehold == null || nextUid == null) return;

    try {
      _subscription =
          _getBalanceSummary(householdId: nextHousehold, meUid: nextUid).listen(
            (summary) {
              if (!_isCurrent(version)) return;
              emit(BalancesStateLoaded(summary));
            },
            onError: (Object error, StackTrace stackTrace) {
              if (!_isCurrent(version)) return;
              emit(BalancesStateFailure(_toFailure(error)));
            },
            onDone: () {
              if (_isCurrent(version)) {
                _subscription = null;
              }
            },
          );
    } catch (error) {
      if (_isCurrent(version)) {
        emit(BalancesStateFailure(_toFailure(error)));
      }
    }
  }

  Future<void> retry() {
    return start(householdId: _householdId, uid: _uid, force: true);
  }

  bool _isCurrent(int version) => !isClosed && version == _session;

  Failure _toFailure(Object error) {
    if (error is Failure) return error;

    return const UnknownFailure(
      'Your balances could not be loaded. Please try again.',
    );
  }

  @override
  Future<void> close() async {
    ++_session;

    final subscription = _subscription;
    _subscription = null;

    await subscription?.cancel();
    await super.close();
  }
}
