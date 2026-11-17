import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'package:changa_app/core/error/result.dart';
import 'package:changa_app/core/theme/app_theme.dart';
import 'package:changa_app/features/auth/domain/entities/app_user.dart';
import 'package:changa_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:changa_app/features/chores/domain/entities/chore.dart';
import 'package:changa_app/features/chores/domain/entities/swap_request.dart';
import 'package:changa_app/features/chores/domain/usecases/complete_chore.dart';
import 'package:changa_app/features/chores/domain/usecases/respond_to_swap.dart';
import 'package:changa_app/features/chores/domain/usecases/watch_all_chores.dart';
import 'package:changa_app/features/chores/domain/usecases/watch_chores_for_day.dart';
import 'package:changa_app/features/chores/domain/usecases/watch_swap_requests.dart';
import 'package:changa_app/features/chores/presentation/pages/chore_roster_page.dart';
import 'package:changa_app/features/household/domain/entities/household.dart';
import 'package:changa_app/features/household/domain/entities/member.dart';
import 'package:changa_app/features/household/presentation/cubit/household_cubit.dart';

class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class MockHouseholdCubit extends MockCubit<HouseholdState>
    implements HouseholdCubit {}

class MockWatchChoresForDay extends Mock implements WatchChoresForDay {}

class MockWatchAllChores extends Mock implements WatchAllChores {}

class MockWatchSwapRequests extends Mock implements WatchSwapRequests {}

class MockCompleteChore extends Mock implements CompleteChore {}

class MockRespondToSwap extends Mock implements RespondToSwap {}

AppUser _user(String uid) => AppUser(
  uid: uid,
  fullName: 'Amara Okoye',
  email: '$uid@example.com',
  phone: '',
  householdId: 'home',
  createdAt: DateTime.utc(2026, 11, 1),
);

final _household = Household(
  id: 'home',
  name: 'Maple House',
  type: HouseholdType.apartment,
  expectedMembers: 2,
  pin: '1234',
  adminUid: 'me',
  createdAt: DateTime.utc(2026, 11, 1),
);

HouseholdStateLoaded _loaded() => HouseholdStateLoaded(
  household: _household,
  members: [
    Member(
      uid: 'me',
      role: MemberRole.admin,
      credits: 40,
      joinedAt: DateTime.utc(2026, 11, 1),
    ),
    Member(
      uid: 'kevin',
      role: MemberRole.member,
      credits: 10,
      joinedAt: DateTime.utc(2026, 11, 2),
    ),
  ],
  memberNames: const {'me': 'Amara Okoye', 'kevin': 'Kevin Mugo'},
  currentMember: Member(
    uid: 'me',
    role: MemberRole.admin,
    credits: 40,
    joinedAt: DateTime.utc(2026, 11, 1),
  ),
);

Chore _chore(String id, String title, String assignee) {
  final now = DateTime.now();
  return Chore(
    id: id,
    title: title,
    difficulty: ChoreDifficulty.medium,
    assignedToUid: assignee,
    dueDate: DateTime(now.year, now.month, now.day),
    status: ChoreStatus.pending,
    createdByUid: 'me',
    createdAt: now.subtract(const Duration(days: 3)),
  );
}

void main() {
  final sl = GetIt.instance;

  late MockAuthCubit auth;
  late MockHouseholdCubit household;
  late MockWatchChoresForDay watchDay;
  late MockWatchAllChores watchAll;
  late MockWatchSwapRequests watchSwaps;
  late MockCompleteChore complete;
  late MockRespondToSwap respond;

  setUpAll(() => registerFallbackValue(DateTime(2026)));

  setUp(() async {
    await sl.reset();
    auth = MockAuthCubit();
    household = MockHouseholdCubit();
    watchDay = MockWatchChoresForDay();
    watchAll = MockWatchAllChores();
    watchSwaps = MockWatchSwapRequests();
    complete = MockCompleteChore();
    respond = MockRespondToSwap();

    whenListen(
      auth,
      const Stream<AuthState>.empty(),
      initialState: Authenticated(_user('me')),
    );
    whenListen(
      household,
      const Stream<HouseholdState>.empty(),
      initialState: _loaded(),
    );
    when(() => watchDay(any(), any()))
        .thenAnswer((_) => Stream.value(const []));
    when(() => watchAll(any())).thenAnswer((_) => Stream.value(const []));
    when(() => watchSwaps(any(), any()))
        .thenAnswer((_) => Stream.value(const []));

    sl
      ..registerSingleton<WatchChoresForDay>(watchDay)
      ..registerSingleton<WatchAllChores>(watchAll)
      ..registerSingleton<WatchSwapRequests>(watchSwaps)
      ..registerSingleton<CompleteChore>(complete)
      ..registerSingleton<RespondToSwap>(respond);
  });

  tearDown(() => sl.reset());

  Widget page() => MaterialApp(
    theme: AppTheme.lightTheme,
    home: MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>.value(value: auth),
        BlocProvider<HouseholdCubit>.value(value: household),
      ],
      child: const ChoreRosterPage(),
    ),
  );

  group('before the roster can show', () {
    testWidgets('waits while the household loads', (tester) async {
      whenListen(
        household,
        const Stream<HouseholdState>.empty(),
        initialState: const HouseholdStateLoading(),
      );

      await tester.pumpWidget(page());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('asks to sign in when signed out', (tester) async {
      whenListen(
        auth,
        const Stream<AuthState>.empty(),
        initialState: const Unauthenticated(),
      );

      await tester.pumpWidget(page());

      expect(find.text('Please sign in'), findsOneWidget);
    });

    testWidgets('explains when there is no household', (tester) async {
      whenListen(
        household,
        const Stream<HouseholdState>.empty(),
        initialState: const HouseholdStateEmpty(),
      );

      await tester.pumpWidget(page());

      expect(find.text('No household yet'), findsOneWidget);
    });
  });

  group('the roster', () {
    testWidgets('shows the header and your credits', (tester) async {
      await tester.pumpWidget(page());
      await tester.pump();

      expect(find.text('Chore Roster'), findsOneWidget);
      expect(find.text('You: 40 pts'), findsOneWidget);
      expect(find.byTooltip('Add a chore'), findsOneWidget);
    });

    testWidgets('says so when nothing is planned', (tester) async {
      await tester.pumpWidget(page());
      await tester.pump();

      expect(find.text('Nothing planned for Today'), findsOneWidget);
    });

    testWidgets('lists today’s chores with actions only on yours', (
      tester,
    ) async {
      when(() => watchDay(any(), any())).thenAnswer(
        (_) => Stream.value([
          _chore('c1', 'Wash dishes', 'me'),
          _chore('c2', 'Take out bins', 'kevin'),
        ]),
      );

      await tester.pumpWidget(page());
      await tester.pump();

      expect(find.text('Wash dishes'), findsOneWidget);
      expect(find.text('Take out bins'), findsOneWidget);
      expect(find.text('Kevin · Due today'), findsOneWidget);
      expect(find.text('Mark Done'), findsOneWidget);
      expect(find.byTooltip('Swap this chore'), findsOneWidget);
    });

    testWidgets('Mark Done completes the chore', (tester) async {
      when(() => watchDay(any(), any()))
          .thenAnswer((_) => Stream.value([_chore('c1', 'Wash dishes', 'me')]));
      when(() => complete('home', 'c1'))
          .thenAnswer((_) async => Result<void>.success(null));

      await tester.pumpWidget(page());
      await tester.pump();
      await tester.tap(find.text('Mark Done'));
      await tester.pump();

      verify(() => complete('home', 'c1')).called(1);
    });

    testWidgets('shows a request waiting for your answer', (tester) async {
      when(() => watchSwaps(any(), any())).thenAnswer(
        (_) => Stream.value([
          SwapRequest(
            id: 'r1',
            choreId: 'c2',
            fromUid: 'kevin',
            toUid: 'me',
            status: SwapStatus.pending,
            createdAt: DateTime(2026, 11, 10),
          ),
        ]),
      );
      when(() => watchAll(any())).thenAnswer(
        (_) => Stream.value([_chore('c2', 'Take out bins', 'kevin')]),
      );

      await tester.pumpWidget(page());
      await tester.pump();

      expect(
        find.text('Kevin wants to swap Take out bins with you'),
        findsOneWidget,
      );
      expect(find.text('Accept'), findsOneWidget);
      expect(find.text('Decline'), findsOneWidget);
    });

    testWidgets('a failing chore stream offers to try again', (tester) async {
      when(() => watchDay(any(), any()))
          .thenAnswer((_) => Stream<List<Chore>>.error(Exception('offline')));

      await tester.pumpWidget(page());
      await tester.pump();

      expect(find.text('Couldn’t load chores'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });
  });

  group('landscape', () {
    testWidgets('fits a short, wide screen without overflowing', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 360);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      when(() => watchDay(any(), any())).thenAnswer(
        (_) => Stream.value([
          _chore('c1', 'Wash dishes', 'me'),
          _chore('c2', 'Take out bins', 'kevin'),
        ]),
      );
      when(() => watchSwaps(any(), any())).thenAnswer(
        (_) => Stream.value([
          SwapRequest(
            id: 'r1',
            choreId: 'c2',
            fromUid: 'kevin',
            toUid: 'me',
            status: SwapStatus.pending,
            createdAt: DateTime(2026, 11, 10),
          ),
        ]),
      );

      await tester.pumpWidget(page());
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Chore Roster'), findsOneWidget);
      expect(find.text('Accept'), findsOneWidget);
    });
  });
}
