import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/usecases/mark_all_read.dart';
import '../../domain/usecases/mark_notification_read.dart';
import '../../domain/usecases/watch_unread_notifications.dart';
import 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit(
    this._watchUnread,
    this._markNotificationRead,
    this._markAllRead,
  ) : super(NotificationsState());

  final WatchUnreadNotifications _watchUnread;
  final MarkNotificationRead _markNotificationRead;
  final MarkAllRead _markAllRead;

  StreamSubscription<List<AppNotification>>? _subscription;

  final Set<String> _seenIds = {};

  String? _uid;
  String? _householdId;
  bool _hasBaseline = false;
  int _sessionVersion = 0;

  /// Call when the authenticated user or household changes.
  ///
  /// Pass null IDs on sign-out or when there is no household.
  Future<void> start({
    required String? uid,
    required String? householdId,
    bool force = false,
  }) async {
    if (isClosed) return;

    final nextUid = uid == null || uid.isEmpty ? null : uid;
    final nextHouseholdId = householdId == null || householdId.isEmpty
        ? null
        : householdId;

    final sessionChanged = nextUid != _uid || nextHouseholdId != _householdId;

    if (!force &&
        !sessionChanged &&
        _subscription != null &&
        state.status != NotificationsStatus.failure) {
      return;
    }

    final version = ++_sessionVersion;

    _uid = nextUid;
    _householdId = nextHouseholdId;

    final previousSubscription = _subscription;
    _subscription = null;

    if (sessionChanged) {
      _seenIds.clear();
      _hasBaseline = false;
    }

    // Clear the previous session's data before waiting for cancellation.
    if (sessionChanged) {
      emit(NotificationsState());
    }

    await previousSubscription?.cancel();

    if (!_isCurrent(version)) return;

    if (nextUid == null || nextHouseholdId == null) {
      emit(NotificationsState());
      return;
    }

    emit(
      state.copyWith(status: NotificationsStatus.loading, clearFailure: true),
    );

    try {
      _subscription = _watchUnread(nextUid).listen(
        (notifications) => _onNotifications(notifications, version),
        onError: (Object error, StackTrace stackTrace) {
          _onStreamError(error, version);
        },
        onDone: () {
          if (_isCurrent(version)) {
            _subscription = null;
          }
        },
      );
    } catch (error) {
      _onStreamError(error, version);
    }
  }

  void _onNotifications(List<AppNotification> notifications, int version) {
    if (!_isCurrent(version)) return;

    final unreadIds = notifications.map((item) => item.id).toSet();

    // Remove queued alerts that were read on this or another device.
    final alerts = state.pendingAlerts
        .where((item) => unreadIds.contains(item.id))
        .toList();

    if (_hasBaseline) {
      // The repository supplies newest first. Queue new alerts oldest first.
      alerts.addAll(
        notifications.reversed.where((item) => !_seenIds.contains(item.id)),
      );
    }

    // The initial snapshot fills the inbox without replaying old alerts.
    _hasBaseline = true;
    _seenIds.addAll(unreadIds);

    emit(
      state.copyWith(
        status: NotificationsStatus.loaded,
        unread: notifications,
        pendingAlerts: alerts,
        clearFailure: true,
      ),
    );
  }

  void _onStreamError(Object error, int version) {
    if (!_isCurrent(version)) return;

    emit(
      state.copyWith(
        status: NotificationsStatus.failure,
        failure: _friendlyFailure(error),
      ),
    );
  }

  Future<void> retry() async {
    if (isClosed || _uid == null || _householdId == null) return;

    await start(uid: _uid, householdId: _householdId, force: true);
  }

  Future<void> markRead(String notificationId) async {
    if (isClosed || _uid == null || _householdId == null) return;

    final version = _sessionVersion;

    try {
      final result = await _markNotificationRead(notificationId);

      if (!_isCurrent(version)) return;

      final failure = result.failureOrNull;

      if (failure != null) {
        emit(state.copyWith(failure: failure));
      }
    } catch (error) {
      if (_isCurrent(version)) {
        emit(state.copyWith(failure: _friendlyFailure(error)));
      }
    }
  }

  Future<void> markAllRead() async {
    final uid = _uid;

    if (isClosed || uid == null || _householdId == null) return;

    final version = _sessionVersion;

    try {
      final result = await _markAllRead(uid);

      if (!_isCurrent(version)) return;

      final failure = result.failureOrNull;

      if (failure != null) {
        emit(state.copyWith(failure: failure));
      }
    } catch (error) {
      if (_isCurrent(version)) {
        emit(state.copyWith(failure: _friendlyFailure(error)));
      }
    }
  }

  /// Removes the banner from the queue without marking the item as read.
  void dismissAlert(String notificationId) {
    if (isClosed) return;

    emit(
      state.copyWith(
        pendingAlerts: state.pendingAlerts
            .where((item) => item.id != notificationId)
            .toList(),
      ),
    );
  }

  void clearActionFailure() {
    if (isClosed || state.status == NotificationsStatus.failure) return;

    emit(state.copyWith(clearFailure: true));
  }

  bool _isCurrent(int version) {
    return !isClosed && version == _sessionVersion;
  }

  Failure _friendlyFailure(Object error) {
    return error is Failure ? error : const UnknownFailure();
  }

  @override
  Future<void> close() async {
    ++_sessionVersion;

    final subscription = _subscription;
    _subscription = null;

    await subscription?.cancel();
    await super.close();
  }
}
