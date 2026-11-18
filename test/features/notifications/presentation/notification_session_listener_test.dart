import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:changa_app/features/auth/domain/entities/app_user.dart';
import 'package:changa_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:changa_app/features/household/domain/entities/household.dart';
import 'package:changa_app/features/household/domain/entities/member.dart';
import 'package:changa_app/features/household/presentation/cubit/household_cubit.dart';
import 'package:changa_app/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:changa_app/features/notifications/presentation/cubit/notifications_state.dart';
import 'package:changa_app/features/notifications/presentation/widgets/notification_session_listener.dart';

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class _MockHouseholdCubit extends MockCubit<HouseholdState>
    implements HouseholdCubit {}

class _MockNotificationsCubit extends MockCubit<NotificationsState>
    implements NotificationsCubit {}

AppUser _user(String uid) {
  return AppUser(
    uid: uid,
    fullName: uid,
    email: '$uid@example.com',
    phone: '',
    householdId: 'home',
    createdAt: DateTime.utc(2026, 11, 18),
  );
}

HouseholdStateLoaded _household({String id = 'home', String uid = 'me'}) {
  final member = Member(
    uid: uid,
    role: MemberRole.admin,
    credits: 0,
    joinedAt: DateTime.utc(2026, 11, 18),
  );

  return HouseholdStateLoaded(
    household: Household(
      id: id,
      name: 'Changa Home',
      type: HouseholdType.apartment,
      expectedMembers: 2,
      pin: '123456',
      adminUid: uid,
      createdAt: DateTime.utc(2026, 11, 18),
    ),
    members: [member],
    memberNames: {uid: uid},
    currentMember: member,
  );
}

void main() {
  late _MockAuthCubit auth;
  late _MockHouseholdCubit household;
  late _MockNotificationsCubit notifications;
  late StreamController<AuthState> authStates;
  late StreamController<HouseholdState> householdStates;

  setUp(() {
    auth = _MockAuthCubit();
    household = _MockHouseholdCubit();
    notifications = _MockNotificationsCubit();

    authStates = StreamController<AuthState>.broadcast(sync: true);
    householdStates = StreamController<HouseholdState>.broadcast(sync: true);

    when(
      () => notifications.start(
        uid: any(named: 'uid'),
        householdId: any(named: 'householdId'),
      ),
    ).thenAnswer((_) async {});

    whenListen(
      notifications,
      const Stream<NotificationsState>.empty(),
      initialState: NotificationsState(),
    );
  });

  tearDown(() async {
    await authStates.close();
    await householdStates.close();
  });

  Future<void> show(
    WidgetTester tester, {
    AuthState? authState,
    HouseholdState? householdState,
  }) async {
    whenListen(
      auth,
      authStates.stream,
      initialState: authState ?? Authenticated(_user('me')),
    );

    whenListen(
      household,
      householdStates.stream,
      initialState: householdState ?? _household(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<AuthCubit>.value(value: auth),
            BlocProvider<HouseholdCubit>.value(value: household),
            BlocProvider<NotificationsCubit>.value(value: notifications),
          ],
          child: const NotificationSessionListener(child: Text('App content')),
        ),
      ),
    );

    await tester.pump();
  }

  testWidgets('starts an already loaded notification session', (tester) async {
    await show(tester);

    verify(() => notifications.start(uid: 'me', householdId: 'home')).called(1);

    expect(find.text('App content'), findsOneWidget);
  });

  testWidgets('signed-out startup has no notification session', (tester) async {
    await show(tester, authState: const Unauthenticated());

    verify(() => notifications.start(uid: null, householdId: null)).called(1);
  });

  testWidgets('sign-out clears the previous notification session', (
    tester,
  ) async {
    await show(tester);
    clearInteractions(notifications);

    authStates.add(const Unauthenticated());
    await tester.pump();

    verify(() => notifications.start(uid: null, householdId: null)).called(1);
  });

  for (final nextState in <HouseholdState>[
    const HouseholdStateLoading(),
    const HouseholdStateEmpty(),
  ]) {
    testWidgets(
      '${nextState.runtimeType} clears the active household subscription',
      (tester) async {
        await show(tester);
        clearInteractions(notifications);

        householdStates.add(nextState);
        await tester.pump();

        verify(() => notifications.start(uid: 'me', householdId: null))
            .called(1);
      },
    );
  }

  testWidgets('household changes start the new household session', (
    tester,
  ) async {
    await show(tester);
    clearInteractions(notifications);

    householdStates.add(_household(id: 'second-home'));
    await tester.pump();

    verify(() => notifications.start(uid: 'me', householdId: 'second-home'))
        .called(1);
  });

  testWidgets('a new account cannot use the previous account household', (
    tester,
  ) async {
    await show(tester);
    clearInteractions(notifications);

    // The old household still belongs to "me".
    authStates.add(Authenticated(_user('grace')));
    await tester.pump();

    verify(() => notifications.start(uid: 'grace', householdId: null))
        .called(1);

    verifyNever(() => notifications.start(uid: 'grace', householdId: 'home'));

    householdStates.add(_household(id: 'grace-home', uid: 'grace'));
    await tester.pump();

    verify(() => notifications.start(uid: 'grace', householdId: 'grace-home'))
        .called(1);
  });
}
