// Cubit managing Activity history screen, month filtering, search, and recent dashboard feed

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:changa_app/core/error/failures.dart';
import 'package:changa_app/features/activity/domain/activity_message_builder.dart';
import 'package:changa_app/features/activity/domain/entities/activity.dart';
import 'package:changa_app/features/activity/domain/usecases/watch_month_activity.dart';
import 'package:changa_app/features/activity/domain/usecases/watch_recent_activity.dart';

part 'activity_state.dart';

class ActivityCubit extends Cubit<ActivityState> {
  final WatchMonthActivity? _watchMonthActivity;
  final WatchRecentActivity? _watchRecentActivity;
  final DateTime Function() _clock;

  StreamSubscription<List<Activity>>? _monthSubscription;
  StreamSubscription<List<Activity>>? _recentSubscription;

  String? _householdId;
  DateTime? _selectedMonth;
  String _searchQuery = '';
  List<Activity> _latestRecent = const [];
  final Set<DateTime> _monthsWithData = <DateTime>{};
  int _session = 0;

  ActivityCubit({
    this._watchMonthActivity,
    this._watchRecentActivity,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       super(const ActivityStateInitial());

  static DateTime normalizeMonth(DateTime date) =>
      DateTime(date.year, date.month, 1);

  DateTime get _currentMonth => normalizeMonth(_clock());

  /// Starts or switches the activity streams for [householdId].
  /// Passing a null or empty [householdId] immediately clears state and
  /// cancels active subscriptions (used on sign-out or leaving a household).
  Future<void> start({
    required String? householdId,
    DateTime? initialMonth,
    List<DateTime> seedMonthsWithData = const [],
    bool force = false,
  }) async {
    if (isClosed) return;

    final cleanHouseholdId = householdId?.trim() ?? '';
    if (cleanHouseholdId.isEmpty) {
      await clear();
      return;
    }

    final targetMonth = normalizeMonth(initialMonth ?? _currentMonth);
    final isSameHousehold = _householdId == cleanHouseholdId;

    if (!force &&
        isSameHousehold &&
        _selectedMonth == targetMonth &&
        _monthSubscription != null) {
      return;
    }

    final version = ++_session;
    final previousMonthSub = _monthSubscription;
    final previousRecentSub = isSameHousehold ? null : _recentSubscription;
    _monthSubscription = null;

    if (!isSameHousehold) {
      _recentSubscription = null;
      _householdId = cleanHouseholdId;
      _searchQuery = '';
      _latestRecent = const [];
      _monthsWithData
        ..clear()
        ..addAll(seedMonthsWithData.map(normalizeMonth));
    } else if (seedMonthsWithData.isNotEmpty) {
      _monthsWithData.addAll(seedMonthsWithData.map(normalizeMonth));
    }

    _selectedMonth = targetMonth;

    emit(
      ActivityStateLoading(
        recentActivities: _latestRecent,
        availableMonths: _buildAvailableMonths(),
        selectedMonth: targetMonth,
        searchQuery: _searchQuery,
      ),
    );

    await previousMonthSub?.cancel();
    await previousRecentSub?.cancel();

    if (!_isCurrent(version)) return;

    if (!isSameHousehold || _recentSubscription == null) {
      _subscribeRecent(cleanHouseholdId, version);
    }
    _subscribeMonth(cleanHouseholdId, targetMonth, version);
  }

  /// Convenience alias for loading a household's activity history.
  Future<void> load({
    required String householdId,
    DateTime? month,
    List<DateTime> seedMonthsWithData = const [],
    bool force = false,
  }) {
    return start(
      householdId: householdId,
      initialMonth: month,
      seedMonthsWithData: seedMonthsWithData,
      force: force,
    );
  }

  /// Watches the 5 most recent activities for the Dashboard (Task C integration).
  Stream<List<Activity>> watchRecentForDashboard(
    String householdId, {
    int limit = 5,
  }) {
    final watcher = _watchRecentActivity;
    if (watcher == null || householdId.trim().isEmpty) {
      return Stream.value(const <Activity>[]);
    }
    return watcher(householdId: householdId.trim(), limit: limit);
  }

  /// Switches the selected month tab and subscribes to that month's range.
  Future<void> selectMonth(DateTime month) async {
    if (isClosed) return;
    final currentHousehold = _householdId;
    if (currentHousehold == null || currentHousehold.isEmpty) return;

    final normalized = normalizeMonth(month);
    if (_selectedMonth == normalized &&
        _monthSubscription != null &&
        state is ActivityStateLoaded) {
      return;
    }

    final version = ++_session;
    final previousMonthSub = _monthSubscription;
    _monthSubscription = null;
    _selectedMonth = normalized;

    emit(
      ActivityStateLoading(
        recentActivities: _latestRecent,
        availableMonths: _buildAvailableMonths(),
        selectedMonth: normalized,
        searchQuery: _searchQuery,
      ),
    );

    await previousMonthSub?.cancel();
    if (!_isCurrent(version)) return;

    _subscribeMonth(currentHousehold, normalized, version);
  }

  /// Updates the search query and filters the currently loaded month's lines.
  void search(String query) {
    if (isClosed) return;
    _searchQuery = query;
    final currentState = state;
    if (currentState is ActivityStateLoaded) {
      emit(currentState.copyWith(searchQuery: query));
    } else if (currentState is ActivityStateLoading) {
      emit(
        ActivityStateLoading(
          recentActivities: currentState.recentActivities,
          availableMonths: currentState.availableMonths,
          selectedMonth: currentState.selectedMonth,
          searchQuery: query,
        ),
      );
    } else if (currentState is ActivityStateFailure) {
      emit(
        ActivityStateFailure(
          currentState.failure,
          recentActivities: currentState.recentActivities,
          availableMonths: currentState.availableMonths,
          selectedMonth: currentState.selectedMonth,
          searchQuery: query,
        ),
      );
    }
  }

  /// Retries loading the currently selected month.
  Future<void> retry() {
    return start(
      householdId: _householdId,
      initialMonth: _selectedMonth,
      force: true,
    );
  }

  /// Clears all state and cancels streams on sign-out or household exit.
  Future<void> clear() async {
    ++_session;
    _householdId = null;
    _selectedMonth = null;
    _searchQuery = '';
    _latestRecent = const [];
    _monthsWithData.clear();

    final monthSub = _monthSubscription;
    final recentSub = _recentSubscription;
    _monthSubscription = null;
    _recentSubscription = null;

    if (!isClosed) {
      emit(const ActivityStateInitial());
    }

    await monthSub?.cancel();
    await recentSub?.cancel();
  }

  void _subscribeRecent(String householdId, int version) {
    final recentWatcher = _watchRecentActivity;
    if (recentWatcher == null) return;

    try {
      _recentSubscription = recentWatcher(
        householdId: householdId,
        limit: 100,
      ).listen(
        (items) {
          if (_householdId != householdId || isClosed) return;
          for (final item in items) {
            _monthsWithData.add(normalizeMonth(item.createdAt));
          }
          _latestRecent = items.take(5).toList();

          final currentState = state;
          if (currentState is ActivityStateLoaded) {
            emit(
              currentState.copyWith(
                recentActivities: _latestRecent,
                availableMonths: _buildAvailableMonths(),
              ),
            );
          }
        },
        onError: (_) {
          // Non-fatal: month subscription handles screen-level errors.
        },
      );
    } catch (_) {
      // Ignored if watchRecentActivity is unstubbed in isolated month tests.
    }
  }

  void _subscribeMonth(
    String householdId,
    DateTime targetMonth,
    int version,
  ) {
    final monthWatcher = _watchMonthActivity;
    if (monthWatcher == null) {
      emit(
        ActivityStateFailure(
          const UnknownFailure('Activity feed stream is not configured.'),
          recentActivities: _latestRecent,
          availableMonths: _buildAvailableMonths(),
          selectedMonth: targetMonth,
          searchQuery: _searchQuery,
        ),
      );
      return;
    }

    try {
      _monthSubscription = monthWatcher(
        householdId: householdId,
        month: targetMonth,
      ).listen(
        (activities) {
          if (!_isCurrent(version)) return;

          if (activities.isNotEmpty) {
            _monthsWithData.add(targetMonth);
            for (final activity in activities) {
              _monthsWithData.add(normalizeMonth(activity.createdAt));
            }
          }

          final sorted = List<Activity>.of(activities)
            ..sort((a, b) {
              final cmp = b.createdAt.compareTo(a.createdAt);
              return cmp != 0 ? cmp : a.id.compareTo(b.id);
            });

          emit(
            ActivityStateLoaded(
              activities: sorted,
              recentActivities: _latestRecent,
              availableMonths: _buildAvailableMonths(),
              selectedMonth: targetMonth,
              searchQuery: _searchQuery,
            ),
          );
        },
        onError: (Object error) {
          if (!_isCurrent(version)) return;
          emit(
            ActivityStateFailure(
              _toFailure(error),
              recentActivities: _latestRecent,
              availableMonths: _buildAvailableMonths(),
              selectedMonth: targetMonth,
              searchQuery: _searchQuery,
            ),
          );
        },
        onDone: () {
          if (_isCurrent(version)) {
            _monthSubscription = null;
          }
        },
      );
    } catch (error) {
      if (_isCurrent(version)) {
        emit(
          ActivityStateFailure(
            _toFailure(error),
            recentActivities: _latestRecent,
            availableMonths: _buildAvailableMonths(),
            selectedMonth: targetMonth,
            searchQuery: _searchQuery,
          ),
        );
      }
    }
  }

  /// Returns only months that have data, plus the current month (and active
  /// selected month), sorted newest first.
  List<DateTime> _buildAvailableMonths() {
    final months = <DateTime>{
      _currentMonth,
      ?_selectedMonth,
      ..._monthsWithData,
    }.toList()
      ..sort((a, b) => b.compareTo(a));
    return months;
  }

  bool _isCurrent(int version) => !isClosed && version == _session;

  Failure _toFailure(Object error) {
    if (error is Failure) return error;
    return const UnknownFailure(
      'Your activity history could not be loaded. Please try again.',
    );
  }

  @override
  Future<void> close() async {
    ++_session;
    final monthSub = _monthSubscription;
    final recentSub = _recentSubscription;
    _monthSubscription = null;
    _recentSubscription = null;
    await monthSub?.cancel();
    await recentSub?.cancel();
    await super.close();
  }
}