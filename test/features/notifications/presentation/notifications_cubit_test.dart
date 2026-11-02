import 'dart:async';

import 'package:changa_app/core/error/failures.dart';
import 'package:changa_app/core/error/result.dart';
import 'package:changa_app/features/notifications/domain/entities/app_notification.dart';
import 'package:changa_app/features/notifications/domain/repositories/notification_repository.dart';
import 'package:changa_app/features/notifications/domain/usecases/mark_all_read.dart';
import 'package:changa_app/features/notifications/domain/usecases/mark_notification_read.dart';
import 'package:changa_app/features/notifications/domain/usecases/watch_unread_notifications.dart';
import 'package:changa_app/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:changa_app/features/notifications/presentation/cubit/notifications_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeNotificationRepository repository;
  late NotificationsCubit cubit;

  Future<void> start({String uid = 'me', String householdId = 'household-1'}) {
    return cubit.start(uid: uid, householdId: householdId);
  }

  setUp(() {
    repository = FakeNotificationRepository();

    cubit = NotificationsCubit(
      WatchUnreadNotifications(repository),
      MarkNotificationRead(repository),
      MarkAllRead(repository),
    );
  });

  tearDown(() async {
    if (!cubit.isClosed) {
      await cubit.close();
    }

    await repository.dispose();
  });

  test('first snapshot fills unread list without replaying alerts', () async {
    await start();

    expect(cubit.state.status, NotificationsStatus.loading);

    repository.send('me', [_notification('existing')]);

    expect(cubit.state.status, NotificationsStatus.loaded);
    expect(cubit.state.unreadCount, 1);
    expect(cubit.state.unread.single.id, 'existing');
    expect(cubit.state.pendingAlerts, isEmpty);
  });

  test('new notifications are queued only once', () async {
    await start();

    final existing = _notification('existing');
    final incoming = _notification('new');

    repository.send('me', [existing]);
    repository.send('me', [incoming, existing]);

    expect(cubit.state.pendingAlerts.map((item) => item.id), ['new']);

    // Repeating the same snapshot must not queue another alert.
    repository.send('me', [incoming, existing]);

    expect(cubit.state.pendingAlerts.map((item) => item.id), ['new']);
  });

  test('dismissing an alert does not mark the notification as read', () async {
    await start();

    repository.send('me', []);
    repository.send('me', [_notification('new')]);

    cubit.dismissAlert('new');

    expect(cubit.state.pendingAlerts, isEmpty);
    expect(cubit.state.unreadCount, 1);
    expect(repository.markedReadIds, isEmpty);

    // A later snapshot must not replay the dismissed alert.
    repository.send('me', [_notification('new')]);

    expect(cubit.state.pendingAlerts, isEmpty);
  });

  test('reading on another device removes the queued alert', () async {
    await start();

    repository.send('me', []);
    repository.send('me', [_notification('new')]);

    expect(cubit.state.currentAlert?.id, 'new');

    // The unread stream no longer contains the notification.
    repository.send('me', []);

    expect(cubit.state.unreadCount, 0);
    expect(cubit.state.pendingAlerts, isEmpty);
  });

  test(
    'stream failures are friendly and retry starts another listener',
    () async {
      await start();

      repository.send('me', [_notification('existing')]);

      const failure = NetworkFailure();
      repository.sendError('me', failure);

      expect(cubit.state.status, NotificationsStatus.failure);
      expect(cubit.state.failure, same(failure));

      await cubit.retry();

      expect(repository.watchedUids, ['me', 'me']);
      expect(repository.cancelCount, 1);
      expect(cubit.state.status, NotificationsStatus.loading);

      repository.send('me', [_notification('new'), _notification('existing')]);

      expect(cubit.state.status, NotificationsStatus.loaded);
      expect(cubit.state.failure, isNull);
      expect(cubit.state.pendingAlerts.map((item) => item.id), ['new']);
    },
  );

  test('changing users clears old data and cancels the old listener', () async {
    await start();

    repository.send('me', []);
    repository.send('me', [_notification('old-user-alert')]);

    await start(uid: 'other-user', householdId: 'household-2');

    expect(repository.cancelCount, 1);
    expect(cubit.state.unread, isEmpty);
    expect(cubit.state.pendingAlerts, isEmpty);

    // Updates from the cancelled account cannot affect the new session.
    repository.send('me', [_notification('late-old-user-update')]);

    expect(cubit.state.unread, isEmpty);

    repository.send('other-user', [
      _notification('other-user-item', recipientUid: 'other-user'),
    ]);

    expect(cubit.state.unread.single.recipientUid, 'other-user');
    expect(cubit.state.pendingAlerts, isEmpty);
  });

  test('changing household restarts the listener for the same user', () async {
    await start();

    repository.send('me', []);
    repository.send('me', [_notification('old-household-alert')]);

    await start(householdId: 'household-2');

    expect(repository.watchedUids, ['me', 'me']);
    expect(repository.cancelCount, 1);
    expect(cubit.state.unread, isEmpty);
    expect(cubit.state.pendingAlerts, isEmpty);

    repository.send('me', [_notification('new-household-item')]);

    expect(cubit.state.unread.single.id, 'new-household-item');
    expect(cubit.state.pendingAlerts, isEmpty);
  });

  test('signing out clears state and stops listening', () async {
    await start();

    repository.send('me', [_notification('existing')]);

    await cubit.start(uid: null, householdId: null);

    expect(repository.cancelCount, 1);
    expect(cubit.state.status, NotificationsStatus.initial);
    expect(cubit.state.unread, isEmpty);
    expect(cubit.state.pendingAlerts, isEmpty);

    repository.send('me', [_notification('late')]);

    expect(cubit.state.unread, isEmpty);
  });

  test('does not subscribe when there is no household', () async {
    await cubit.start(uid: 'me', householdId: null);

    expect(repository.watchedUids, isEmpty);
    expect(cubit.state.status, NotificationsStatus.initial);
  });

  test(
    'markRead delegates and waits for the stream to update unread',
    () async {
      await start();

      repository.send('me', [_notification('existing')]);

      await cubit.markRead('existing');

      expect(repository.markedReadIds, ['existing']);
      expect(cubit.state.unreadCount, 1);

      repository.send('me', []);

      expect(cubit.state.unreadCount, 0);
    },
  );

  test('markAllRead forwards the current user and exposes failures', () async {
    await start();

    const failure = PermissionFailure();
    repository.markAllResult = Result<void>.failure(failure);

    await cubit.markAllRead();

    expect(repository.markedAllUids, ['me']);
    expect(cubit.state.failure, same(failure));

    cubit.clearActionFailure();

    expect(cubit.state.failure, isNull);
  });

  test('late action failure after sign-out is ignored', () async {
    await start();

    final gate = Completer<Result<void>>();
    repository.markReadGate = gate;

    final marking = cubit.markRead('existing');

    await cubit.start(uid: null, householdId: null);

    gate.complete(Result<void>.failure(const NetworkFailure()));

    await marking;

    expect(cubit.state.status, NotificationsStatus.initial);
    expect(cubit.state.failure, isNull);
    expect(cubit.state.unread, isEmpty);
  });

  test('closing cancels the stream and ignores a late action result', () async {
    await start();

    final gate = Completer<Result<void>>();
    repository.markReadGate = gate;

    final marking = cubit.markRead('existing');

    await cubit.close();

    expect(repository.cancelCount, 1);

    gate.complete(Result<void>.failure(const NetworkFailure()));

    await expectLater(marking, completes);
    expect(cubit.isClosed, isTrue);
  });
}

class FakeNotificationRepository implements NotificationRepository {
  final List<String> watchedUids = [];
  final List<String> markedReadIds = [];
  final List<String> markedAllUids = [];

  final Map<String, List<StreamController<List<AppNotification>>>> _streams =
      {};

  int cancelCount = 0;

  Result<void> markReadResult = Result<void>.success(null);
  Result<void> markAllResult = Result<void>.success(null);

  Completer<Result<void>>? markReadGate;

  @override
  Stream<List<AppNotification>> watchUnread(String uid) {
    watchedUids.add(uid);

    final controller = StreamController<List<AppNotification>>(
      sync: true,
      onCancel: () {
        cancelCount++;
      },
    );

    _streams.putIfAbsent(uid, () => []).add(controller);

    return controller.stream;
  }

  void send(String uid, List<AppNotification> notifications) {
    _streams[uid]!.last.add(notifications);
  }

  void sendError(String uid, Object error) {
    _streams[uid]!.last.addError(error, StackTrace.current);
  }

  @override
  Future<Result<void>> markRead(String notificationId) {
    markedReadIds.add(notificationId);

    final gate = markReadGate;

    return gate == null
        ? Future<Result<void>>.value(markReadResult)
        : gate.future;
  }

  @override
  Future<Result<void>> markAllRead(String uid) async {
    markedAllUids.add(uid);
    return markAllResult;
  }

  Future<void> dispose() async {
    for (final controllers in _streams.values) {
      for (final controller in controllers) {
        await controller.close();
      }
    }
  }
}

AppNotification _notification(String id, {String recipientUid = 'me'}) {
  return AppNotification(
    id: id,
    recipientUid: recipientUid,
    actorUid: 'kevin',
    type: 'nudge',
    title: 'A friendly reminder',
    body: 'Tap to see the details.',
    refId: 'kevin',
    read: false,
    createdAt: DateTime.utc(2026, 11, 1),
  );
}
