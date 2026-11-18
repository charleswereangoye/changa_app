import 'dart:async';
import 'dart:convert';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:changa_app/core/services/local_notification_service.dart';
import 'package:changa_app/features/auth/domain/entities/app_user.dart';
import 'package:changa_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:changa_app/features/household/domain/entities/household.dart';
import 'package:changa_app/features/household/domain/entities/member.dart';
import 'package:changa_app/features/household/presentation/cubit/household_cubit.dart';
import 'package:changa_app/features/notifications/domain/entities/app_notification.dart';
import 'package:changa_app/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:changa_app/features/notifications/presentation/cubit/notifications_state.dart';
import 'package:changa_app/features/notifications/presentation/widgets/local_notification_listener.dart';
import 'package:changa_app/features/profile/presentation/cubit/preferences_cubit.dart';
import 'package:changa_app/features/profile/presentation/cubit/preferences_state.dart';

class _MockAuth extends MockCubit<AuthState> implements AuthCubit {}

class _MockHousehold extends MockCubit<HouseholdState>
    implements HouseholdCubit {}

class _MockNotifications extends MockCubit<NotificationsState>
    implements NotificationsCubit {}

class _MockPreferences extends MockCubit<PreferencesState>
    implements PreferencesCubit {}

class _MockService extends Mock implements LocalNotificationService {}

AppNotification _notice(String id) => AppNotification(
  id: id,
  recipientUid: 'me',
  actorUid: 'jean',
  type: 'nudge',
  title: 'Reminder $id',
  body: 'Please check your balance.',
  read: false,
  createdAt: DateTime.utc(2026, 11, 18),
);

String _payload({String recipientUid = 'me', String householdId = 'home'}) =>
    jsonEncode({
      'notificationId': 'notice',
      'type': 'nudge',
      'recipientUid': recipientUid,
      'actorUid': 'jean',
      'householdId': householdId,
    });

void main() {
  late _MockAuth auth;
  late _MockHousehold household;
  late _MockNotifications notifications;
  late _MockPreferences preferences;
  late _MockService service;

  late StreamController<AuthState> authStates;
  late StreamController<NotificationsState> notificationStates;
  late NotificationsState notificationState;

  late void Function(String) onTap;
  late List<String> shownIds;
  late List<AppNotification> opened;
  String? launchPayload;

  void publish(NotificationsState state) {
    notificationState = state;
    notificationStates.add(state);
  }

  setUp(() {
    auth = _MockAuth();
    household = _MockHousehold();
    notifications = _MockNotifications();
    preferences = _MockPreferences();
    service = _MockService();

    authStates = StreamController<AuthState>.broadcast();
    notificationStates = StreamController<NotificationsState>.broadcast();

    notificationState = NotificationsState(status: NotificationsStatus.loaded);
    shownIds = [];
    opened = [];
    launchPayload = null;

    final date = DateTime.utc(2026, 11, 18);
    final member = Member(
      uid: 'me',
      role: MemberRole.admin,
      credits: 0,
      joinedAt: date,
    );

    whenListen(
      auth,
      authStates.stream,
      initialState: Authenticated(
        AppUser(
          uid: 'me',
          fullName: 'Amara',
          email: 'amara@example.com',
          phone: '',
          householdId: 'home',
          createdAt: date,
        ),
      ),
    );

    whenListen(
      household,
      const Stream<HouseholdState>.empty(),
      initialState: HouseholdStateLoaded(
        household: Household(
          id: 'home',
          name: 'Changa Home',
          type: HouseholdType.apartment,
          expectedMembers: 2,
          pin: '123456',
          adminUid: 'me',
          createdAt: date,
        ),
        members: [member],
        memberNames: const {'me': 'Amara'},
        currentMember: member,
      ),
    );

    whenListen(
      preferences,
      const Stream<PreferencesState>.empty(),
      initialState: const PreferencesState(isLoaded: true),
    );

    when(() => notifications.state).thenAnswer((_) => notificationState);
    when(() => notifications.stream)
        .thenAnswer((_) => notificationStates.stream);

    when(() => notifications.markRead(any())).thenAnswer((_) async {});

    when(() => notifications.dismissAlert(any())).thenAnswer((invocation) {
      final id = invocation.positionalArguments.single as String;

      publish(
        notificationState.copyWith(
          pendingAlerts: notificationState.pendingAlerts
              .where((notification) => notification.id != id)
              .toList(),
        ),
      );
    });

    when(() => service.initialize(onTap: any(named: 'onTap')))
        .thenAnswer((invocation) async {
          onTap = invocation.namedArguments[#onTap] as void Function(String);
        });

    when(() => service.getLaunchPayload())
        .thenAnswer((_) async => launchPayload);

    when(() => service.cancelAll()).thenAnswer((_) async {});

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
    ).thenAnswer((invocation) async {
      shownIds.add(invocation.namedArguments[#notificationId] as String);
      return true;
    });
  });

  tearDown(() async {
    await authStates.close();
    await notificationStates.close();
  });

  Future<void> show(WidgetTester tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>.value(value: auth),
          BlocProvider<HouseholdCubit>.value(value: household),
          BlocProvider<NotificationsCubit>.value(value: notifications),
          BlocProvider<PreferencesCubit>.value(value: preferences),
        ],
        child: MaterialApp(
          home: LocalNotificationListener(
            service: service,
            onOpen: opened.add,
            child: const Scaffold(body: Text('App content')),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  Future<void> finish(WidgetTester tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }

  testWidgets('only new background alerts use Android delivery', (
    tester,
  ) async {
    await show(tester);

    final foreground = _notice('foreground');
    publish(
      NotificationsState(
        status: NotificationsStatus.loaded,
        unread: [foreground],
        pendingAlerts: [foreground],
      ),
    );
    await tester.pumpAndSettle();

    expect(shownIds, isEmpty);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();

    final background = _notice('background');
    publish(
      NotificationsState(
        status: NotificationsStatus.loaded,
        unread: [background, foreground],
        pendingAlerts: [foreground, background],
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(shownIds, ['background']);

    await finish(tester);
  });

  testWidgets(
    'a matching tap opens the current notification and marks it read',
    (tester) async {
      final notification = _notice('notice');
      notificationState = NotificationsState(
        status: NotificationsStatus.loaded,
        unread: [notification],
      );

      await show(tester);

      onTap(_payload());
      await tester.pumpAndSettle();

      expect(opened, [notification]);
      verify(() => notifications.markRead('notice')).called(1);

      await finish(tester);
    },
  );

  testWidgets('taps for another account or household are ignored', (
    tester,
  ) async {
    notificationState = NotificationsState(
      status: NotificationsStatus.loaded,
      unread: [_notice('notice')],
    );

    await show(tester);

    onTap(_payload(recipientUid: 'grace'));
    await tester.pumpAndSettle();

    onTap(_payload(householdId: 'other-home'));
    await tester.pumpAndSettle();

    expect(opened, isEmpty);
    verifyNever(() => notifications.markRead(any()));

    await finish(tester);
  });

  testWidgets('a launch tap waits for notification data to load', (
    tester,
  ) async {
    launchPayload = _payload();
    notificationState = NotificationsState(status: NotificationsStatus.loading);

    await show(tester);

    expect(opened, isEmpty);

    final notification = _notice('notice');
    publish(
      NotificationsState(
        status: NotificationsStatus.loaded,
        unread: [notification],
      ),
    );
    await tester.pumpAndSettle();

    expect(opened, [notification]);
    verify(() => notifications.markRead('notice')).called(1);

    await finish(tester);
  });

  testWidgets('sign-out clears displayed notifications and blocks late taps', (
    tester,
  ) async {
    notificationState = NotificationsState(
      status: NotificationsStatus.loaded,
      unread: [_notice('notice')],
    );

    await show(tester);
    clearInteractions(service);

    authStates.add(const Unauthenticated());
    await tester.pumpAndSettle();

    verify(() => service.cancelAll()).called(1);

    onTap(_payload());
    await tester.pumpAndSettle();

    expect(opened, isEmpty);
    verifyNever(() => notifications.markRead(any()));

    await finish(tester);
  });
}
