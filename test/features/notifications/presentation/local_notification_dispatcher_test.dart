import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:changa_app/core/services/local_notification_service.dart';
import 'package:changa_app/features/notifications/domain/entities/app_notification.dart';
import 'package:changa_app/features/notifications/presentation/logic/local_notification_dispatcher.dart';

class _MockService extends Mock implements LocalNotificationService {}

AppNotification _notice({
  String id = 'notice-1',
  String recipientUid = 'amara',
  String type = 'nudge',
}) {
  return AppNotification(
    id: id,
    recipientUid: recipientUid,
    actorUid: 'jean',
    type: type,
    title: 'Changa update',
    body: 'Please check your household.',
    read: false,
    createdAt: DateTime.utc(2026, 11, 18),
    refId: 'expense-1',
  );
}

void main() {
  late _MockService service;
  late LocalNotificationDispatcher dispatcher;
  late List<Object> errors;

  void stubShow(Future<bool> Function(Invocation invocation) answer) {
    when(
      () => service.show(
        notificationId: any(named: 'notificationId'),
        type: any(named: 'type'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        notifyNudges: any(named: 'notifyNudges'),
        notifyChores: any(named: 'notifyChores'),
        refId: any(named: 'refId'),
        recipientUid: any(named: 'recipientUid'),
        actorUid: any(named: 'actorUid'),
        householdId: any(named: 'householdId'),
      ),
    ).thenAnswer(answer);
  }

  void dispatch({
    List<AppNotification>? alerts,
    bool foreground = false,
    bool notifyNudges = true,
    bool notifyChores = true,
  }) {
    dispatcher.dispatch(
      pendingAlerts: alerts ?? [_notice()],
      isForeground: foreground,
      notifyNudges: notifyNudges,
      notifyChores: notifyChores,
    );
  }

  setUp(() async {
    service = _MockService();
    errors = [];

    when(() => service.cancelAll()).thenAnswer((_) async {});
    stubShow((_) async => true);

    dispatcher = LocalNotificationDispatcher(
      service,
      onError: (error, stackTrace) => errors.add(error),
    );

    dispatcher.updateSession(uid: 'amara', householdId: 'home-1');
    await dispatcher.idle;

    clearInteractions(service);
  });

  test('delivers a background alert with its session information', () async {
    dispatch();
    await dispatcher.idle;

    verify(
      () => service.show(
        notificationId: 'notice-1',
        type: 'nudge',
        title: 'Changa update',
        body: 'Please check your household.',
        notifyNudges: true,
        notifyChores: true,
        refId: 'expense-1',
        recipientUid: 'amara',
        actorUid: 'jean',
        householdId: 'home-1',
      ),
    ).called(1);

    expect(errors, isEmpty);
  });

  test('does not deliver the same alert twice', () async {
    dispatch();
    dispatch();
    await dispatcher.idle;

    verify(
      () => service.show(
        notificationId: 'notice-1',
        type: 'nudge',
        title: 'Changa update',
        body: 'Please check your household.',
        notifyNudges: true,
        notifyChores: true,
        refId: 'expense-1',
        recipientUid: 'amara',
        actorUid: 'jean',
        householdId: 'home-1',
      ),
    ).called(1);
  });

  test('foreground alerts are not replayed after backgrounding', () async {
    dispatch(foreground: true);
    dispatch(foreground: false);
    await dispatcher.idle;

    verifyZeroInteractions(service);
  });

  test('muted nudges and chore updates are skipped', () async {
    dispatch(
      alerts: [
        _notice(id: 'nudge', type: 'nudge'),
        _notice(id: 'request', type: 'swapRequest'),
        _notice(id: 'response', type: 'swapResponse'),
      ],
      notifyNudges: false,
      notifyChores: false,
    );
    await dispatcher.idle;

    verifyZeroInteractions(service);
  });

  test('alerts for another account are ignored', () async {
    dispatch(alerts: [_notice(recipientUid: 'grace')]);
    await dispatcher.idle;

    verifyZeroInteractions(service);
  });

  test(
    'sign-out invalidates queued delivery and clears notifications',
    () async {
      dispatch();

      // Sign out before the queued show operation starts.
      dispatcher.updateSession(uid: null, householdId: null);
      await dispatcher.idle;

      verify(() => service.cancelAll()).called(1);
      verifyNoMoreInteractions(service);
    },
  );

  test(
    'account switching clears an in-progress old-account alert first',
    () async {
      final started = Completer<void>();
      final release = Completer<void>();
      final events = <String>[];

      when(() => service.cancelAll()).thenAnswer((_) async {
        events.add('cancel');
      });

      stubShow((invocation) async {
        final id = invocation.namedArguments[#notificationId] as String;
        events.add('show:$id');

        if (id == 'notice-1') {
          started.complete();
          await release.future;
        }

        return true;
      });

      dispatch();
      await started.future;

      dispatcher.updateSession(uid: 'grace', householdId: 'home-2');
      dispatch(
        alerts: [_notice(id: 'grace-notice', recipientUid: 'grace')],
      );

      release.complete();
      await dispatcher.idle;

      expect(events, ['show:notice-1', 'cancel', 'show:grace-notice']);
      expect(errors, isEmpty);
    },
  );

  test('a delivery failure does not block later notifications', () async {
    final attempted = <String>[];

    stubShow((invocation) async {
      final id = invocation.namedArguments[#notificationId] as String;
      attempted.add(id);

      if (id == 'first') {
        throw StateError('Delivery failed');
      }

      return true;
    });

    dispatch(
      alerts: [
        _notice(id: 'first'),
        _notice(id: 'second'),
      ],
    );
    await dispatcher.idle;

    expect(attempted, ['first', 'second']);
    expect(errors, hasLength(1));
    expect(errors.single, isA<StateError>());
  });
}
