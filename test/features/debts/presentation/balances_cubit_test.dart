import 'dart:async';

import 'package:changa_app/core/error/failures.dart';
import 'package:changa_app/features/debts/domain/entities/balance_summary.dart';
import 'package:changa_app/features/debts/domain/usecases/get_balance_summary.dart';
import 'package:changa_app/features/debts/presentation/cubit/balances_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetBalanceSummary extends Mock implements GetBalanceSummary {}

void main() {
  late _MockGetBalanceSummary getBalanceSummary;
  late StreamController<BalanceSummary> controller;
  late BalancesCubit cubit;

  final summary = BalanceSummary(
    youAreOwed: 14000,
    youOwe: 4000,
    net: 10000,
    byMember: {'kevin': 14000, 'grace': -4000},
  );

  setUp(() {
    getBalanceSummary = _MockGetBalanceSummary();
    controller = StreamController<BalanceSummary>.broadcast(sync: true);

    when(
      () => getBalanceSummary(
        householdId: any(named: 'householdId'),
        meUid: any(named: 'meUid'),
      ),
    ).thenAnswer((_) => controller.stream);

    cubit = BalancesCubit(getBalanceSummary);
  });

  tearDown(() async {
    if (!cubit.isClosed) {
      await cubit.close();
    }
    await controller.close();
  });

  Future<void> start() {
    return cubit.start(householdId: 'home', uid: 'me');
  }

  test('starts in the initial state', () {
    expect(cubit.state, isA<BalancesStateInitial>());
    verifyZeroInteractions(getBalanceSummary);
  });

  test('loads the summary for the current user and household', () async {
    await start();

    expect(cubit.state, isA<BalancesStateLoading>());
    expect(controller.hasListener, isTrue);

    controller.add(summary);

    final state = cubit.state as BalancesStateLoaded;
    expect(state.summary.youAreOwed, 14000);
    expect(state.summary.youOwe, 4000);
    expect(state.summary.net, 10000);
    expect(state.summary.byMember, {'kevin': 14000, 'grace': -4000});

    verify(() => getBalanceSummary(householdId: 'home', meUid: 'me')).called(1);
  });

  test('updates when another summary arrives', () async {
    await start();
    controller.add(summary);

    final settled = BalanceSummary(
      youAreOwed: 0,
      youOwe: 0,
      net: 0,
      byMember: {},
    );

    controller.add(settled);

    expect((cubit.state as BalancesStateLoaded).summary, settled);
  });

  test('does not subscribe without both session IDs', () async {
    await cubit.start(householdId: null, uid: 'me');
    await cubit.start(householdId: 'home', uid: null);
    await cubit.start(householdId: '', uid: 'me');

    expect(cubit.state, isA<BalancesStateInitial>());
    expect(controller.hasListener, isFalse);
    verifyZeroInteractions(getBalanceSummary);
  });

  test('starting the same active session does not resubscribe', () async {
    await start();
    controller.add(summary);

    await start();

    expect(cubit.state, isA<BalancesStateLoaded>());
    verify(() => getBalanceSummary(householdId: 'home', meUid: 'me')).called(1);
  });

  test('preserves domain failures from the stream', () async {
    await start();

    const failure = NetworkFailure();
    controller.addError(failure);

    expect((cubit.state as BalancesStateFailure).failure, same(failure));
  });

  test('converts unexpected errors into a friendly failure', () async {
    await start();

    controller.addError(StateError('Internal implementation detail'));

    final failure = (cubit.state as BalancesStateFailure).failure;
    expect(failure, isA<UnknownFailure>());
    expect(
      failure.message,
      'Your balances could not be loaded. Please try again.',
    );
  });

  test('retry resubscribes and can recover', () async {
    await start();
    controller.addError(const NetworkFailure());

    await cubit.retry();

    expect(cubit.state, isA<BalancesStateLoading>());

    controller.add(summary);

    expect(cubit.state, isA<BalancesStateLoaded>());
    verify(() => getBalanceSummary(householdId: 'home', meUid: 'me')).called(2);
  });

  test('household switching clears the previous balance immediately', () async {
    await start();
    controller.add(summary);

    final switching = cubit.start(householdId: 'another-home', uid: 'me');

    // Old balances disappear before subscription cancellation completes.
    expect(cubit.state, isA<BalancesStateLoading>());

    await switching;

    verify(() => getBalanceSummary(householdId: 'another-home', meUid: 'me'))
        .called(1);
  });

  test('switching users subscribes for the new user', () async {
    await start();
    controller.add(summary);

    await cubit.start(householdId: 'home', uid: 'grace');

    expect(cubit.state, isA<BalancesStateLoading>());
    verify(() => getBalanceSummary(householdId: 'home', meUid: 'grace'))
        .called(1);
  });

  test('sign-out clears balances and cancels the subscription', () async {
    await start();
    controller.add(summary);

    final signingOut = cubit.start(householdId: null, uid: null);

    expect(cubit.state, isA<BalancesStateInitial>());

    await signingOut;

    expect(controller.hasListener, isFalse);

    controller.add(summary);
    expect(cubit.state, isA<BalancesStateInitial>());
  });

  test('handles a use case that throws before returning a stream', () async {
    when(() => getBalanceSummary(householdId: 'home', meUid: 'me'))
        .thenThrow(const PermissionFailure());

    await start();

    expect(
      (cubit.state as BalancesStateFailure).failure,
      isA<PermissionFailure>(),
    );
  });

  test(
    'close cancels the subscription and start after close is ignored',
    () async {
      await start();

      await cubit.close();

      expect(controller.hasListener, isFalse);

      await cubit.start(householdId: 'another-home', uid: 'grace');

      verifyNever(
        () => getBalanceSummary(householdId: 'another-home', meUid: 'grace'),
      );
    },
  );
}
