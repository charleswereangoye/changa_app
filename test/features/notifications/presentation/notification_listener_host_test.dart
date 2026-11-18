import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:changa_app/core/widgets/alert_modal.dart';
import 'package:changa_app/features/auth/domain/entities/app_user.dart';
import 'package:changa_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:changa_app/features/household/domain/entities/household.dart';
import 'package:changa_app/features/household/domain/entities/member.dart';
import 'package:changa_app/features/household/presentation/cubit/household_cubit.dart';
import 'package:changa_app/features/notifications/domain/entities/app_notification.dart';
import 'package:changa_app/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:changa_app/features/notifications/presentation/cubit/notifications_state.dart';
import 'package:changa_app/features/notifications/presentation/widgets/in_app_banner.dart';
import 'package:changa_app/features/notifications/presentation/widgets/notification_listener_host.dart';
import 'package:changa_app/features/profile/presentation/cubit/preferences_cubit.dart';
import 'package:changa_app/features/profile/presentation/cubit/preferences_state.dart';

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class _MockHouseholdCubit extends MockCubit<HouseholdState>
    implements HouseholdCubit {}

class _MockNotificationsCubit extends MockCubit<NotificationsState>
    implements NotificationsCubit {}

class _MockPreferencesCubit extends MockCubit<PreferencesState>
    implements PreferencesCubit {}

AppNotification _notification({
  String id = 'notice',
  String type = 'newExpense',
}) {
  return AppNotification(
    id: id,
    recipientUid: 'me',
    actorUid: 'jean',
    type: type,
    title: 'Notification $id',
    body: 'A shared household update.',
    read: false,
    createdAt: DateTime.utc(2026, 11, 18),
  );
}

void main() {
  late _MockAuthCubit auth;
  late _MockHouseholdCubit household;
  late _MockNotificationsCubit notifications;
  late _MockPreferencesCubit preferences;

  late StreamController<AuthState> authStates;
  late StreamController<NotificationsState> notificationStates;
  late NotificationsState notificationState;
  late List<AppNotification> opened;

  void publish(NotificationsState state) {
    notificationState = state;
    notificationStates.add(state);
  }

  setUp(() {
    auth = _MockAuthCubit();
    household = _MockHouseholdCubit();
    notifications = _MockNotificationsCubit();
    preferences = _MockPreferencesCubit();

    authStates = StreamController<AuthState>.broadcast(sync: true);
    notificationStates = StreamController<NotificationsState>.broadcast();
    notificationState = NotificationsState(status: NotificationsStatus.loaded);
    opened = [];

    final createdAt = DateTime.utc(2026, 11, 18);
    final user = AppUser(
      uid: 'me',
      fullName: 'Amara',
      email: 'amara@example.com',
      phone: '',
      householdId: 'home',
      createdAt: createdAt,
    );
    final member = Member(
      uid: 'me',
      role: MemberRole.admin,
      credits: 0,
      joinedAt: createdAt,
    );

    whenListen(auth, authStates.stream, initialState: Authenticated(user));

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
          createdAt: createdAt,
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

    when(
      () => notifications.start(
        uid: any(named: 'uid'),
        householdId: any(named: 'householdId'),
      ),
    ).thenAnswer((_) async {});

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
  });

  tearDown(() async {
    await authStates.close();
    await notificationStates.close();
  });

  Future<void> show(WidgetTester tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>.value(value: auth),
          BlocProvider<HouseholdCubit>.value(value: household),
          BlocProvider<NotificationsCubit>.value(value: notifications),
          BlocProvider<PreferencesCubit>.value(value: preferences),
        ],
        child: MaterialApp(
          navigatorKey: navigatorKey,
          builder: (context, child) => NotificationListenerHost(
            navigatorKey: navigatorKey,
            onOpen: opened.add,
            child: child!,
          ),
          home: const Scaffold(body: Text('App content')),
        ),
      ),
    );

    await tester.pump();
  }

  Future<void> queue(WidgetTester tester, AppNotification notification) async {
    publish(
      NotificationsState(
        status: NotificationsStatus.loaded,
        unread: [notification],
        pendingAlerts: [notification],
      ),
    );

    await tester.pumpAndSettle();
  }

  testWidgets('closing a banner keeps the notification unread', (tester) async {
    await show(tester);
    await queue(tester, _notification());

    expect(find.byType(InAppBanner), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('notification-banner-dismiss')));
    await tester.pump();

    expect(find.byType(InAppBanner), findsNothing);
    expect(notificationState.unread, hasLength(1));
    expect(opened, isEmpty);
    verifyNever(() => notifications.markRead(any()));
  });

  testWidgets('opening an expense marks it read and opens its details', (
    tester,
  ) async {
    final notification = _notification();

    await show(tester);
    await queue(tester, notification);

    await tester.tap(find.byKey(const ValueKey('notification-banner-open')));
    await tester.pump();

    expect(find.byType(InAppBanner), findsNothing);
    expect(opened, [notification]);
    verify(() => notifications.markRead(notification.id)).called(1);
  });

  testWidgets('a nudge opens its modal before opening details', (tester) async {
    final notification = _notification(type: 'nudge');

    await show(tester);
    await queue(tester, notification);

    await tester.tap(find.byKey(const ValueKey('notification-banner-open')));
    await tester.pumpAndSettle();

    expect(find.byType(AlertModal), findsOneWidget);
    expect(find.text(notification.body), findsOneWidget);
    expect(opened, isEmpty);
    verifyNever(() => notifications.markRead(any()));

    await tester.tap(find.text('View Details'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertModal), findsNothing);
    expect(opened, [notification]);
    verify(() => notifications.markRead(notification.id)).called(1);
  });

  testWidgets('muted nudges are dismissed without marking them read', (
    tester,
  ) async {
    when(
      () => preferences.state,
    ).thenReturn(const PreferencesState(isLoaded: true, notifyNudges: false));

    await show(tester);
    await queue(tester, _notification(type: 'nudge'));

    expect(find.byType(InAppBanner), findsNothing);
    expect(notificationState.pendingAlerts, isEmpty);
    expect(notificationState.unread, hasLength(1));
    expect(opened, isEmpty);
    verifyNever(() => notifications.markRead(any()));
  });

  testWidgets('signing out removes an open nudge modal', (tester) async {
    await show(tester);
    await queue(tester, _notification(type: 'nudge'));

    await tester.tap(find.byKey(const ValueKey('notification-banner-open')));
    await tester.pumpAndSettle();

    expect(find.byType(AlertModal), findsOneWidget);

    authStates.add(const Unauthenticated());
    await tester.pumpAndSettle();

    expect(find.byType(AlertModal), findsNothing);
    expect(find.byType(InAppBanner), findsNothing);
    expect(opened, isEmpty);
    verifyNever(() => notifications.markRead(any()));
    expect(tester.takeException(), isNull);
  });
}
