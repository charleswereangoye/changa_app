// Owner: C - Person C (Expenses, Dashboard, Documentation)
// Description: Cubit combining streams for the main Dashboard view

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:changa_app/core/constants/app_constants.dart';
import 'package:changa_app/features/activity/domain/entities/activity.dart';
import 'package:changa_app/features/chores/domain/entities/chore.dart';
import 'package:changa_app/features/dashboard/domain/entities/harmony_score.dart';
import 'package:changa_app/features/dashboard/domain/logic/calculate_harmony_score.dart';
import 'package:changa_app/features/debts/domain/entities/balance_summary.dart';
import 'package:changa_app/features/debts/domain/entities/debt.dart';
import 'package:changa_app/features/debts/domain/logic/balance_calculator.dart';

part 'dashboard_state.dart';

typedef WatchPendingDebtsFn = Stream<List<Debt>> Function(String householdId);
typedef WatchDebtsSinceFn = Stream<List<Debt>> Function(
  String householdId,
  DateTime since,
);
typedef WatchChoresFn = Stream<List<Chore>> Function(String householdId);
typedef WatchRecentActivityFn = Stream<List<Activity>> Function(
  String householdId,
);

/// Balances and activity each load on their own.
///
/// The Harmony Score needs three sources: all pending debts (an old unpaid
/// debt must still count), debts from the last 30 days (recent settled ones)
/// and chores. If ANY of them fails, Harmony is reported as failed
/// (unavailable) instead of a score built from the sources that did load,
/// because that could show a perfect 100 for a house with unpaid bills.
/// The next successful event from the failed source brings it back.
class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit({
    required this._watchPendingDebts,
    required this._watchDebtsSince,
    required this._watchChores,
    required this._watchRecentActivity,
    this._balanceCalculator = const BalanceCalculator(),
    this._calculateHarmony = const CalculateHarmonyScore(),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       super(const DashboardState());

  final WatchPendingDebtsFn _watchPendingDebts;
  final WatchDebtsSinceFn _watchDebtsSince;
  final WatchChoresFn _watchChores;
  final WatchRecentActivityFn _watchRecentActivity;
  final BalanceCalculator _balanceCalculator;
  final CalculateHarmonyScore _calculateHarmony;
  final DateTime Function() _clock;

  final List<StreamSubscription<Object?>> _subscriptions = [];
  int _session = 0;
  String? _householdId;
  String? _uid;

  // Latest value from each Harmony source (null until it first emits).
  List<Debt>? _pendingDebts;
  List<Debt>? _debtsSince;
  List<Chore>? _chores;
  bool _pendingFailed = false;
  bool _sinceFailed = false;
  bool _choresFailed = false;

  /// Call when the signed-in person or their household changes. Pass null
  /// for either when there is no household yet or after sign-out.
  Future<void> start({
    required String? householdId,
    required String? uid,
    bool force = false,
  }) async {
    if (isClosed) return;

    final nextHousehold = (householdId == null || householdId.isEmpty)
        ? null
        : householdId;
    final nextUid = (uid == null || uid.isEmpty) ? null : uid;

    if (!force &&
        _subscriptions.isNotEmpty &&
        nextHousehold == _householdId &&
        nextUid == _uid) {
      return;
    }

    final version = ++_session;
    _householdId = nextHousehold;
    _uid = nextUid;
    _pendingDebts = null;
    _debtsSince = null;
    _chores = null;
    _pendingFailed = false;
    _sinceFailed = false;
    _choresFailed = false;

    await _cancelAll();
    if (!_isCurrent(version)) return;

    if (nextHousehold == null || nextUid == null) {
      emit(const DashboardState(hasHousehold: false));
      return;
    }

    emit(const DashboardState());

    final since = _clock().subtract(
      const Duration(days: AppConstants.harmonyDebtWindowDays),
    );

    // All pending debts: drives the balance AND the Harmony payment score.
    _listen<List<Debt>>(
      version,
      () => _watchPendingDebts(nextHousehold),
      (debts) {
        _pendingDebts = debts;
        _pendingFailed = false;
        emit(
          state.copyWith(
            balanceStatus: DashboardSection.ready,
            balance: _balanceCalculator.summarize(
              pendingDebts: debts,
              meUid: nextUid,
            ),
          ),
        );
        _recomputeHarmony();
      },
      (_) {
        _pendingFailed = true;
        emit(state.copyWith(balanceStatus: DashboardSection.failed));
        _recomputeHarmony();
      },
    );

    // Recent debts, including settled ones, for the payment score.
    _listen<List<Debt>>(
      version,
      () => _watchDebtsSince(nextHousehold, since),
      (debts) {
        _debtsSince = debts;
        _sinceFailed = false;
        _recomputeHarmony();
      },
      (_) {
        _sinceFailed = true;
        _recomputeHarmony();
      },
    );

    _listen<List<Chore>>(
      version,
      () => _watchChores(nextHousehold),
      (chores) {
        _chores = chores;
        _choresFailed = false;
        _recomputeHarmony();
      },
      (_) {
        _choresFailed = true;
        _recomputeHarmony();
      },
    );

    _listen<List<Activity>>(
      version,
      () => _watchRecentActivity(nextHousehold),
      (items) => emit(
        state.copyWith(
          activityStatus: DashboardSection.ready,
          recentActivity: List<Activity>.unmodifiable(items),
        ),
      ),
      (_) => emit(state.copyWith(activityStatus: DashboardSection.failed)),
    );
  }

  Future<void> retry() =>
      start(householdId: _householdId, uid: _uid, force: true);

  void _listen<T>(
    int version,
    Stream<T> Function() open,
    void Function(T value) onData,
    void Function(Object error) onError,
  ) {
    try {
      final subscription = open().listen(
        (value) {
          if (_isCurrent(version)) onData(value);
        },
        onError: (Object error, StackTrace stackTrace) {
          if (_isCurrent(version)) onError(error);
        },
      );
      _subscriptions.add(subscription);
    } catch (error) {
      // A source that is not ready yet (for example a data layer another
      // teammate has not finished) fails its own section only.
      if (_isCurrent(version)) onError(error);
    }
  }

  /// Pending debts plus recent debts, one entry per debt ID. If both streams
  /// carry the same debt, a settled copy wins because settling cannot be
  /// undone and one stream may be a moment behind the other.
  static List<Debt> _mergeDebts(List<Debt> pending, List<Debt> recent) {
    final byId = <String, Debt>{for (final debt in pending) debt.id: debt};
    for (final debt in recent) {
      final existing = byId[debt.id];
      if (existing == null || !existing.isSettled) {
        byId[debt.id] = debt;
      }
    }
    return byId.values.toList();
  }

  void _recomputeHarmony() {
    // A failed source means the score would be incomplete: unavailable.
    if (_pendingFailed || _sinceFailed || _choresFailed) {
      emit(
        state.copyWith(
          harmonyStatus: DashboardSection.failed,
          clearHarmony: true,
        ),
      );
      return;
    }

    final pending = _pendingDebts;
    final recent = _debtsSince;
    final chores = _chores;
    if (pending == null || recent == null || chores == null) {
      // A source recovered but another one has not loaded yet.
      if (state.harmonyStatus == DashboardSection.failed) {
        emit(
          state.copyWith(
            harmonyStatus: DashboardSection.loading,
            clearHarmony: true,
          ),
        );
      }
      return;
    }

    final score = _calculateHarmony(
      chores: chores,
      debts: _mergeDebts(pending, recent),
      now: _clock(),
    );
    emit(
      state.copyWith(
        harmonyStatus: DashboardSection.ready,
        harmony: score,
        clearHarmony: score == null,
      ),
    );
  }

  Future<void> _cancelAll() async {
    final old = List<StreamSubscription<Object?>>.of(_subscriptions);
    _subscriptions.clear();
    await Future.wait(old.map((subscription) => subscription.cancel()));
  }

  bool _isCurrent(int version) => !isClosed && version == _session;

  @override
  Future<void> close() async {
    ++_session;
    await _cancelAll();
    return super.close();
  }
}
