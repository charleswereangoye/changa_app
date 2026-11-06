import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:changa_app/core/error/result.dart';
import 'package:changa_app/core/theme/app_theme.dart';
import 'package:changa_app/features/auth/domain/entities/app_user.dart';
import 'package:changa_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:changa_app/features/debts/domain/entities/debt.dart';
import 'package:changa_app/features/debts/domain/entities/debt_status.dart';
import 'package:changa_app/features/debts/domain/usecases/send_nudge.dart';
import 'package:changa_app/features/debts/domain/usecases/watch_debts_between.dart';
import 'package:changa_app/features/debts/presentation/pages/debt_detail_route.dart';
import 'package:changa_app/features/expenses/domain/entities/expense.dart';
import 'package:changa_app/features/expenses/domain/usecases/watch_expenses.dart';
import 'package:changa_app/features/profile/domain/usecases/watch_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class _MockWatchUser extends Mock implements WatchUser {}

class _MockWatchDebtsBetween extends Mock implements WatchDebtsBetween {}

class _MockWatchExpenses extends Mock implements WatchExpenses {}

class _MockSendNudge extends Mock implements SendNudge {}

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
  late _MockWatchDebtsBetween watchDebts;
  late _MockWatchExpenses watchExpenses;
  late StreamController<AuthState> authStates;

  late Map<String, List<StreamController<AppUser?>>> profiles;
  late Map<String, List<StreamController<List<Debt>>>> debtStreams;
  late Map<String, List<StreamController<List<Expense>>>> expenseStreams;

  setUp(() async {
    await sl.reset();

    auth = _MockAuthCubit();
    watchUser = _MockWatchUser();
    watchDebts = _MockWatchDebtsBetween();
    watchExpenses = _MockWatchExpenses();
    final sendNudge = _MockSendNudge();

    authStates = StreamController<AuthState>.broadcast();
    profiles = {};
    debtStreams = {};
    expenseStreams = {};

    // Single-subscription streams expose accidental stream reuse.
    when(() => watchUser(any())).thenAnswer((invocation) {
      final uid = invocation.positionalArguments[0] as String;
      final controller = StreamController<AppUser?>();
      profiles.putIfAbsent(uid, () => []).add(controller);
      return controller.stream;
    });

    when(() => watchDebts(any(), any(), any())).thenAnswer((invocation) {
      final householdId = invocation.positionalArguments[0] as String;
      final controller = StreamController<List<Debt>>();
      debtStreams.putIfAbsent(householdId, () => []).add(controller);
      return controller.stream;
    });

    when(() => watchExpenses(any())).thenAnswer((invocation) {
      final householdId = invocation.positionalArguments[0] as String;
      final controller = StreamController<List<Expense>>();
      expenseStreams.putIfAbsent(householdId, () => []).add(controller);
      return controller.stream;
    });

    when(
      () => sendNudge(
        householdId: any(named: 'householdId'),
        fromUid: any(named: 'fromUid'),
        toUid: any(named: 'toUid'),
      ),
    ).thenAnswer((_) async => Result<void>.success(null));

    sl.registerSingleton<WatchUser>(watchUser);
    sl.registerSingleton<WatchDebtsBetween>(watchDebts);
    sl.registerSingleton<WatchExpenses>(watchExpenses);
    sl.registerSingleton<SendNudge>(sendNudge);
  });

  tearDown(() async {
    await authStates.close();

    for (final controllers in profiles.values) {
      for (final controller in controllers) {
        await controller.close();
      }
    }

    for (final controllers in debtStreams.values) {
      for (final controller in controllers) {
        await controller.close();
      }
    }

    for (final controllers in expenseStreams.values) {
      for (final controller in controllers) {
        await controller.close();
      }
    }

    await sl.reset();
  });

  Future<void> flush(WidgetTester tester) async {
    await tester.pump();
    await tester.pump();
    await tester.pump();
  }

  Future<void> mount(
    WidgetTester tester, {
    AuthState? initialState,
    String otherUid = 'kevin',
  }) async {
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
          child: DebtDetailRoute(otherUid: otherUid),
        ),
      ),
    );

    await flush(tester);
  }

  Future<void> emitBalance(
    WidgetTester tester, {
    String householdId = 'home',
    String meUid = 'me',
  }) async {
    debtStreams[householdId]!.last.add([
      Debt(
        id: 'debt-1',
        expenseId: 'expense-1',
        debtorUid: 'kevin',
        creditorUid: meUid,
        amount: 6000,
        creditsApplied: 0,
        status: DebtStatus.pending,
        createdAt: DateTime.utc(2026, 11, 1),
      ),
    ]);

    expenseStreams[householdId]!.last.add([]);
    await flush(tester);
  }

  Future<void> ready(WidgetTester tester) async {
    await mount(tester);

    profiles['me']!.last.add(_user('me'));
    profiles['kevin']!.last.add(_user('kevin', name: 'Kevin'));

    await flush(tester);
    await emitBalance(tester);
  }

  testWidgets('signed-out users cannot open debt streams', (tester) async {
    await mount(tester, initialState: const Unauthenticated());

    expect(
      find.text('Please sign in to view your shared balances.'),
      findsOneWidget,
    );
    verifyZeroInteractions(watchUser);
    verifyZeroInteractions(watchDebts);
  });

  testWidgets('rejects opening my own debt detail', (tester) async {
    await mount(tester, otherUid: 'me');

    expect(
      find.text('Choose a housemate to view shared balances.'),
      findsOneWidget,
    );
    verifyZeroInteractions(watchUser);
    verifyZeroInteractions(watchDebts);
  });

  testWidgets('requires a household before opening debt streams', (
    tester,
  ) async {
    await mount(tester);

    profiles['me']!.last.add(_user('me', householdId: null));
    await flush(tester);

    expect(
      find.text('Join a household to view shared balances.'),
      findsOneWidget,
    );
    verifyZeroInteractions(watchDebts);
  });

  testWidgets('loads the current household and housemate name', (tester) async {
    await ready(tester);

    expect(find.text('Kevin owes you'), findsOneWidget);

    verify(() => watchDebts('home', 'me', 'kevin')).called(1);
    verify(() => watchExpenses('home')).called(1);
  });

  testWidgets('household switching replaces debt listeners only', (
    tester,
  ) async {
    await ready(tester);

    final oldDebts = debtStreams['home']!.last;
    final oldExpenses = expenseStreams['home']!.last;
    final housemateProfile = profiles['kevin']!.last;

    profiles['me']!.last.add(_user('me', householdId: 'second-home'));
    await flush(tester);

    expect(oldDebts.hasListener, isFalse);
    expect(oldExpenses.hasListener, isFalse);
    expect(housemateProfile.hasListener, isTrue);

    await emitBalance(tester, householdId: 'second-home');

    expect(find.text('Kevin owes you'), findsOneWidget);
    expect(tester.takeException(), isNull);

    verify(() => watchDebts('second-home', 'me', 'kevin')).called(1);
    verify(() => watchUser('kevin')).called(1);
  });

  testWidgets('leaving and rejoining keeps the profile stream usable', (
    tester,
  ) async {
    await ready(tester);

    final oldDebts = debtStreams['home']!.last;

    profiles['me']!.last.add(_user('me', householdId: null));
    await flush(tester);

    expect(oldDebts.hasListener, isFalse);
    expect(
      find.text('Join a household to view shared balances.'),
      findsOneWidget,
    );

    profiles['me']!.last.add(_user('me'));
    await flush(tester);
    await emitBalance(tester);

    expect(find.text('Kevin owes you'), findsOneWidget);
    expect(tester.takeException(), isNull);
    verify(() => watchUser('kevin')).called(1);
  });

  testWidgets('sign-out removes balances and cancels listeners', (
    tester,
  ) async {
    await ready(tester);

    final oldDebts = debtStreams['home']!.last;
    final oldExpenses = expenseStreams['home']!.last;
    final oldProfile = profiles['me']!.last;

    authStates.add(const Unauthenticated());
    await flush(tester);

    expect(find.text('Kevin owes you'), findsNothing);
    expect(
      find.text('Please sign in to view your shared balances.'),
      findsOneWidget,
    );
    expect(oldDebts.hasListener, isFalse);
    expect(oldExpenses.hasListener, isFalse);
    expect(oldProfile.hasListener, isFalse);
  });

  testWidgets('account switching clears the previous account immediately', (
    tester,
  ) async {
    await ready(tester);

    final oldDebts = debtStreams['home']!.last;

    authStates.add(Authenticated(_user('grace', householdId: 'grace-home')));
    await flush(tester);

    // Grace's profile has not arrived yet.
    expect(find.text('Kevin owes you'), findsNothing);
    expect(oldDebts.hasListener, isFalse);

    profiles['grace']!.last.add(_user('grace', householdId: 'grace-home'));
    profiles['kevin']!.last.add(
      _user('kevin', name: 'Kevin', householdId: 'grace-home'),
    );

    await flush(tester);
    await emitBalance(tester, householdId: 'grace-home', meUid: 'grace');

    verify(() => watchDebts('grace-home', 'grace', 'kevin')).called(1);
    expect(find.text('Kevin owes you'), findsOneWidget);
  });

  testWidgets('profile errors show a friendly message', (tester) async {
    await mount(tester);

    profiles['me']!.last.addError(StateError('Internal error'));
    await flush(tester);

    expect(
      find.text('Your profile could not be loaded. Please try again later.'),
      findsOneWidget,
    );
    verifyZeroInteractions(watchDebts);
  });
}
