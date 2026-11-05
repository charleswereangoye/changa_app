import 'dart:convert';

import 'package:changa_app/core/services/local_notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPlugin extends Mock implements FlutterLocalNotificationsPlugin {}

class _MockAndroidPlugin extends Mock
    implements AndroidFlutterLocalNotificationsPlugin {}

void main() {
  late _MockPlugin plugin;
  late _MockAndroidPlugin android;
  late LocalNotificationService service;

  setUpAll(() {
    registerFallbackValue(
      const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
      ),
    );
    registerFallbackValue(const AndroidNotificationChannel('test', 'Test'));
    registerFallbackValue(const NotificationDetails());
  });

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    plugin = _MockPlugin();
    android = _MockAndroidPlugin();
    service = LocalNotificationService(plugin);

    when(
      () => plugin.initialize(
        settings: any(named: 'settings'),
        onDidReceiveNotificationResponse: any(
          named: 'onDidReceiveNotificationResponse',
        ),
      ),
    ).thenAnswer((_) async => true);

    when(
      () => plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >(),
    ).thenReturn(android);

    when(() => android.createNotificationChannel(any()))
        .thenAnswer((_) async {});

    when(() => android.requestNotificationsPermission())
        .thenAnswer((_) async => true);

    when(
      () => plugin.show(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        notificationDetails: any(named: 'notificationDetails'),
        payload: any(named: 'payload'),
      ),
    ).thenAnswer((_) async {});

    when(() => plugin.cancelAll()).thenAnswer((_) async {});
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  Future<bool> show({
    String type = 'nudge',
    bool notifyNudges = true,
    bool notifyChores = true,
  }) {
    return service.show(
      notificationId: 'notification-1',
      type: type,
      title: 'Changa',
      body: 'Please check your balance.',
      notifyNudges: notifyNudges,
      notifyChores: notifyChores,
      refId: 'debt-1',
    );
  }

  test('initializes once and creates the Android channel', () async {
    await service.initialize();
    await service.initialize();

    verify(
      () => plugin.initialize(
        settings: any(named: 'settings'),
        onDidReceiveNotificationResponse: any(
          named: 'onDidReceiveNotificationResponse',
        ),
      ),
    ).called(1);

    final channel =
        verify(() => android.createNotificationChannel(captureAny()))
                .captured
                .single
            as AndroidNotificationChannel;

    expect(channel.id, LocalNotificationService.channelId);
    expect(channel.importance, Importance.high);

    verifyNever(() => android.requestNotificationsPermission());
  });

  test('muted nudges do not call the plugin', () async {
    expect(await show(notifyNudges: false), isFalse);

    verifyZeroInteractions(plugin);
    verifyZeroInteractions(android);
  });

  test('muted chore updates do not call the plugin', () async {
    for (final type in ['swapRequest', 'swapResponse']) {
      expect(await show(type: type, notifyChores: false), isFalse);
    }

    verifyZeroInteractions(plugin);
    verifyZeroInteractions(android);
  });

  test('shows a notification with its navigation payload', () async {
    expect(await show(), isTrue);

    final captured = verify(
      () => plugin.show(
        id: any(named: 'id'),
        title: 'Changa',
        body: 'Please check your balance.',
        notificationDetails: any(named: 'notificationDetails'),
        payload: captureAny(named: 'payload'),
      ),
    ).captured;

    expect(jsonDecode(captured.single as String), {
      'notificationId': 'notification-1',
      'type': 'nudge',
      'refId': 'debt-1',
    });

    verifyNever(() => android.requestNotificationsPermission());
  });

  test('expense notifications ignore nudge and chore preferences', () async {
    expect(
      await show(type: 'newExpense', notifyNudges: false, notifyChores: false),
      isTrue,
    );

    verify(
      () => plugin.show(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        notificationDetails: any(named: 'notificationDetails'),
        payload: any(named: 'payload'),
      ),
    ).called(1);
  });

  test('requests permission only when explicitly asked', () async {
    expect(await service.requestPermission(), isTrue);

    verify(() => android.requestNotificationsPermission()).called(1);
  });

  test('cancelAll clears displayed notifications', () async {
    await service.cancelAll();

    verify(() => plugin.cancelAll()).called(1);
  });

  test('unsupported platforms skip all plugin calls', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    await service.initialize();
    expect(await show(), isFalse);
    expect(await service.requestPermission(), isFalse);
    expect(await service.getLaunchPayload(), isNull);
    await service.cancelAll();

    verifyZeroInteractions(plugin);
    verifyZeroInteractions(android);
  });

  test('failed initialization can be retried', () async {
    when(
      () => plugin.initialize(
        settings: any(named: 'settings'),
        onDidReceiveNotificationResponse: any(
          named: 'onDidReceiveNotificationResponse',
        ),
      ),
    ).thenAnswer((_) async => false);

    await expectLater(service.initialize(), throwsStateError);

    when(
      () => plugin.initialize(
        settings: any(named: 'settings'),
        onDidReceiveNotificationResponse: any(
          named: 'onDidReceiveNotificationResponse',
        ),
      ),
    ).thenAnswer((_) async => true);

    await service.initialize();

    verify(
      () => plugin.initialize(
        settings: any(named: 'settings'),
        onDidReceiveNotificationResponse: any(
          named: 'onDidReceiveNotificationResponse',
        ),
      ),
    ).called(2);

    verify(() => android.createNotificationChannel(any())).called(1);
  });
}
