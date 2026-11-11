import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:changa_app/core/constants/pref_keys.dart';
import 'package:changa_app/core/enums/settlement_method.dart';
import 'package:changa_app/core/error/result.dart';
import 'package:changa_app/core/theme/app_theme.dart';
import 'package:changa_app/features/auth/domain/entities/app_user.dart';
import 'package:changa_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:changa_app/features/debts/domain/entities/balance_summary.dart';
import 'package:changa_app/features/debts/domain/usecases/get_balance_summary.dart';
import 'package:changa_app/features/debts/domain/usecases/settle_between.dart';
import 'package:changa_app/features/debts/presentation/cubit/settle_cubit.dart';
import 'package:changa_app/features/debts/presentation/pages/settle_up_page.dart';
import 'package:changa_app/features/debts/presentation/pages/settle_up_route.dart';
import 'package:changa_app/features/household/domain/entities/member.dart';
import 'package:changa_app/features/household/domain/usecases/watch_members.dart';
import 'package:changa_app/features/profile/domain/services/preferences_service.dart';
import 'package:changa_app/features/profile/domain/usecases/get_users_by_ids.dart';
import 'package:changa_app/features/profile/domain/usecases/watch_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class _MockWatchUser extends Mock implements WatchUser {}

class _MockWatchMembers extends Mock implements WatchMembers {}

class _MockGetUsers extends Mock implements GetUsersByIds {}

class _MockGetBalances extends Mock implements GetBalanceSummary {}

class _MockSettleBetween extends Mock implements SettleBetween {}

class _MockPreferences extends Mock implements PreferencesService {}

AppUser _user(
  String uid, {
  String? householdId = 'home',
  String name = 'Amara',
}) {
  return AppUser(
    uid: uid,
    fullName: name,
    email: '$uid@example.com',
    phone: '',
    householdId: householdId,
    createdAt: DateTime.utc(2026, 11, 1),
  );
}

void main() {
  final sl = GetIt.instance;

  late _MockAuthCubit auth;
  late _MockWatchUser watchUser;
  late _MockWatchMembers watchMembers;
  late _MockGetUsers getUsers;
  late _MockGetBalances getBalances;
  late _MockSettleBetween settleBetween;
  late _MockPreferences preferences;
  late StreamController<AuthState> authStates;

  late Map<String, List<StreamController<AppUser?>>> profiles;
  late Map<String, List<StreamController<BalanceSummary>>> balanceStreams;

  setUpAll(() {
    registerFallbackValue(<String>[]);
  });

  setUp(() async {
    await sl.reset();

    auth = _MockAuthCubit();
    watchUser = _MockWatchUser();
    watchMembers = _MockWatchMembers();
    getUsers = _MockGetUsers();
    getBalances = _MockGetBalances();
    settleBetween = _MockSettleBetween();
    preferences = _MockPreferences();

    authStates = StreamController<AuthState>.broadcast();
    profiles = {};
    balanceStreams = {};

    when(() => watchUser(any())).thenAnswer((invocation) {
      final uid = invocation.positionalArguments[0] as String;
      final controller = StreamController<AppUser?>();
      profiles.putIfAbsent(uid, () => []).add(controller);
      return controller.stream;
    });

    when(() => watchMembers(any())).thenAnswer(
      (_) => Stream.value([
        Member(
          uid: 'kevin',
          role: MemberRole.member,
          credits: 0,
          joinedAt: DateTime.utc(2026, 11, 1),
        ),
      ]),
    );

    when(() => getUsers(any())).thenAnswer(
      (_) async =>
          Result<List<AppUser>>.success([_user('kevin', name: 'Kevin')]),
    );

    when(
      () => getBalances(
        householdId: any(named: 'householdId'),
        meUid: any(named: 'meUid'),
      ),
    ).thenAnswer((invocation) {
      final householdId = invocation.namedArguments[#householdId] as String;
      final controller = StreamController<BalanceSummary>();
      balanceStreams.putIfAbsent(householdId, () => []).add(controller);
      return controller.stream;
    });

    when(
      () => preferences.getString(
        PrefKeys.defaultSettlementMethod,
        fallback: 'momo',
      ),
    ).thenAnswer((_) async => 'bank');

    when(
      () => settleBetween(
        householdId: any(named: 'householdId'),
        meUid: any(named: 'meUid'),
        otherUid: any(named: 'otherUid'),
        method: any(named: 'method'),
      ),
    ).thenAnswer((_) async => Result<void>.success(null));

    sl.registerSingleton<WatchUser>(watchUser);
    sl.registerSingleton<WatchMembers>(watchMembers);
    sl.registerSingleton<GetUsersByIds>(getUsers);
    sl.registerSingleton<GetBalanceSummary>(getBalances);
    sl.registerSingleton<SettleBetween>(settleBetween);
    sl.registerSingleton<PreferencesService>(preferences);
  });

  tearDown(() async {
    await authStates.close();

    for (final controllers in profiles.values) {
      for (final controller in controllers) {
        await controller.close();
      }
    }

    for (final controllers in balanceStreams.values) {
      for (final controller in controllers) {
        await controller.close();
      }
    }

    await sl.reset();
  });

  Future<void> flush(WidgetTester tester) async {
    for (var frame = 0; frame < 6; frame++) {
      await tester.pump();
    }
  }

  Future<void> mount(WidgetTester tester, {AuthState? initialState}) async {
    whenListen(
      auth,
      authStates.stream,
      initialState: initialState ?? Authenticated(_user('me')),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: BlocProvider<AuthCubit>.value(
          value: auth,
          child: const SettleUpRoute(otherUid: 'kevin'),
        ),
      ),
    );

    await flush(tester);
  }

  Future<void> emitBalance(
    WidgetTester tester, {
    String householdId = 'home',
  }) async {
    balanceStreams[householdId]!.last.add(
      BalanceSummary(
        youAreOwed: 6000,
        youOwe: 0,
        net: 6000,
        byMember: {'kevin': 6000},
      ),
    );
    await flush(tester);
  }

  Future<void> ready(WidgetTester tester) async {
    await mount(tester);
    profiles['me']!.last.add(_user('me'));
    await flush(tester);
    await emitBalance(tester);
  }

  SettleCubit pageCubit(WidgetTester tester) {
    return tester.element(find.byType(SettleUpPage)).read<SettleCubit>();
  }

  testWidgets('signed-out users cannot open settlement streams', (
    tester,
  ) async {
    await mount(tester, initialState: const Unauthenticated());

    expect(
      find.text('Please sign in to settle shared balances.'),
      findsOneWidget,
    );
    verifyZeroInteractions(watchUser);
    verifyZeroInteractions(getBalances);
  });

  testWidgets('requires a household before loading balances', (tester) async {
    await mount(tester);

    profiles['me']!.last.add(_user('me', householdId: null));
    await flush(tester);

    expect(
      find.text('Join a household to settle shared balances.'),
      findsOneWidget,
    );
    verifyZeroInteractions(getBalances);
  });

  testWidgets(
    'uses Housemate while profiles load, including settlement success',
    (tester) async {
      final gate = Completer<Result<List<AppUser>>>();

      when(() => getUsers(any())).thenAnswer((_) => gate.future);

      await ready(tester);

      final cubit = pageCubit(tester);

      expect(find.text('Housemate'), findsOneWidget);
      expect(find.text('Former member'), findsNothing);

      await cubit.confirm();
      await flush(tester);

      expect(find.text('All settled with Housemate'), findsOneWidget);
      expect(find.text('All settled with Former member'), findsNothing);

      gate.complete(
        Result<List<AppUser>>.success([_user('kevin', name: 'Kevin')]),
      );
      await flush(tester);

      expect(find.text('All settled with Kevin'), findsOneWidget);
      expect(pageCubit(tester), same(cubit));

      verify(() => getBalances(householdId: 'home', meUid: 'me')).called(1);
    },
  );

  testWidgets('loads saved Bank Transfer and uses it for confirmation', (
    tester,
  ) async {
    await ready(tester);

    expect(pageCubit(tester).state.method, SettlementMethod.bank);
    expect(find.text('Kevin'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('confirm-settlement')),
      150,
      scrollable: find.byType(Scrollable),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('confirm-settlement')));
    await tester.pumpAndSettle();

    verify(
      () => settleBetween(
        householdId: 'home',
        meUid: 'me',
        otherUid: 'kevin',
        method: 'bank',
      ),
    ).called(1);

    expect(find.text('All settled with Kevin'), findsOneWidget);
  });

  for (final raw in ['credits', 'unknown-method']) {
    testWidgets('saved "$raw" falls back to Mobile Money', (tester) async {
      when(
        () => preferences.getString(
          PrefKeys.defaultSettlementMethod,
          fallback: 'momo',
        ),
      ).thenAnswer((_) async => raw);

      await ready(tester);

      expect(pageCubit(tester).state.method, SettlementMethod.momo);
    });
  }

  testWidgets('waits for the saved preference before creating the flow', (
    tester,
  ) async {
    final gate = Completer<String>();

    when(
      () => preferences.getString(
        PrefKeys.defaultSettlementMethod,
        fallback: 'momo',
      ),
    ).thenAnswer((_) => gate.future);

    await mount(tester);
    profiles['me']!.last.add(_user('me'));
    await flush(tester);

    verifyZeroInteractions(getBalances);
    expect(find.byType(SettleUpPage), findsNothing);

    gate.complete('cash');
    await flush(tester);
    await emitBalance(tester);

    expect(pageCubit(tester).state.method, SettlementMethod.cash);
  });

  testWidgets('sign-out removes the page and cancels its listeners', (
    tester,
  ) async {
    await ready(tester);

    final oldBalances = balanceStreams['home']!.last;
    final oldProfile = profiles['me']!.last;

    authStates.add(const Unauthenticated());
    await flush(tester);

    expect(find.byType(SettleUpPage), findsNothing);
    expect(
      find.text('Please sign in to settle shared balances.'),
      findsOneWidget,
    );
    expect(oldBalances.hasListener, isFalse);
    expect(oldProfile.hasListener, isFalse);
  });

  testWidgets('household changes replace the settlement Cubit', (tester) async {
    await ready(tester);

    final oldCubit = pageCubit(tester);
    final oldBalances = balanceStreams['home']!.last;

    profiles['me']!.last.add(_user('me', householdId: 'second-home'));
    await flush(tester);
    await emitBalance(tester, householdId: 'second-home');

    expect(oldCubit.isClosed, isTrue);
    expect(oldBalances.hasListener, isFalse);
    expect(pageCubit(tester).householdId, 'second-home');

    verify(() => getBalances(householdId: 'second-home', meUid: 'me'))
        .called(1);
  });

  testWidgets('account changes clear the previous settlement immediately', (
    tester,
  ) async {
    await ready(tester);

    final oldCubit = pageCubit(tester);
    final oldBalances = balanceStreams['home']!.last;

    authStates.add(Authenticated(_user('grace', householdId: 'grace-home')));
    await flush(tester);

    expect(find.byType(SettleUpPage), findsNothing);
    expect(oldCubit.isClosed, isTrue);
    expect(oldBalances.hasListener, isFalse);

    profiles['grace']!.last.add(_user('grace', householdId: 'grace-home'));
    await flush(tester);
    await emitBalance(tester, householdId: 'grace-home');

    expect(pageCubit(tester).meUid, 'grace');
    expect(pageCubit(tester).householdId, 'grace-home');
  });
}
