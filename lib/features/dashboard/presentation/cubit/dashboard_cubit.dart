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

  // The Harmony Score needs both of these, so keep the latest of each.
  List<Chore>? _chores;
  List<Debt>? _debtsSince;
  bool _choresFailed = false;
  bool _debtsFailed = false;

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
    _chores = null;
    _debtsSince = null;
    _choresFailed = false;
    _debtsFailed = false;

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

    _listen<List<Debt>>(
      version,
      () => _watchPendingDebts(nextHousehold),
      (debts) => emit(
        state.copyWith(
          balanceStatus: DashboardSection.ready,
          balance: _balanceCalculator.summarize(
            pendingDebts: debts,
            meUid: nextUid,
          ),
        ),
      ),
      (_) => emit(state.copyWith(balanceStatus: DashboardSection.failed)),
    );

    _listen<List<Debt>>(
      version,
      () => _watchDebtsSince(nextHousehold, since),
      (debts) {
        _debtsSince = debts;
        _debtsFailed = false;
        _recomputeHarmony();
      },
      (_) {
        _debtsSince = const [];
        _debtsFailed = true;
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
        _chores = const [];
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

  void _recomputeHarmony() {
    final debts = _debtsSince;
    final chores = _chores;
    if (debts == null || chores == null) return;

    if (_debtsFailed && _choresFailed) {
      emit(
        state.copyWith(
          harmonyStatus: DashboardSection.failed,
          clearHarmony: true,
        ),
      );
      return;
    }

    final score = _calculateHarmony(
      chores: chores,
      debts: debts,
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
