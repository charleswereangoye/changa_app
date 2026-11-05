import 'dart:async';

import 'package:changa_app/core/enums/settlement_method.dart';
import 'package:changa_app/core/error/failures.dart';
import 'package:changa_app/core/error/result.dart';
import 'package:changa_app/features/debts/domain/entities/balance_summary.dart';
import 'package:changa_app/features/debts/domain/usecases/get_balance_summary.dart';
import 'package:changa_app/features/debts/domain/usecases/settle_between.dart';
import 'package:changa_app/features/debts/presentation/cubit/settle_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetBalanceSummary extends Mock implements GetBalanceSummary {}

class _MockSettleBetween extends Mock implements SettleBetween {}

void main() {
  late _MockGetBalanceSummary getBalanceSummary;
  late _MockSettleBetween settleBetween;
  late StreamController<BalanceSummary> balances;
  late SettleCubit cubit;

  final summary = BalanceSummary(
    youAreOwed: 14000,
    youOwe: 4000,
    net: 10000,
    byMember: {'kevin': 14000, 'grace': -4000},
  );

  SettleCubit build({
    String? initialOtherUid = 'kevin',
    SettlementMethod defaultMethod = SettlementMethod.momo,
  }) {
    return SettleCubit(
      getBalanceSummary: getBalanceSummary,
      settleBetween: settleBetween,
      householdId: 'home',
      meUid: 'me',
      initialOtherUid: initialOtherUid,
      defaultMethod: defaultMethod,
    );
  }

  setUp(() {
    getBalanceSummary = _MockGetBalanceSummary();
    settleBetween = _MockSettleBetween();
    balances = StreamController<BalanceSummary>.broadcast(sync: true);

    when(() => getBalanceSummary(householdId: 'home', meUid: 'me'))
        .thenAnswer((_) => balances.stream);

    when(
      () => settleBetween(
        householdId: any(named: 'householdId'),
        meUid: any(named: 'meUid'),
        otherUid: any(named: 'otherUid'),
        method: any(named: 'method'),
      ),
    ).thenAnswer((_) async => Result<void>.success(null));

    cubit = build();
  });

  tearDown(() async {
    if (!cubit.isClosed) {
      await cubit.close();
    }
    await balances.close();
  });

  Future<void> ready() async {
    await cubit.load();
    balances.add(summary);
  }

  test('starts with the requested member and Mobile Money', () {
    expect(cubit.state.status, SettleStatus.initial);
    expect(cubit.state.selectedOtherUid, 'kevin');
    expect(cubit.state.method, SettlementMethod.momo);
    expect(cubit.state.canConfirm, isFalse);
  });

  test('loads live balances for the current household', () async {
    await ready();

    expect(cubit.state.status, SettleStatus.loaded);
    expect(cubit.state.selectedBalance, 14000);
    expect(cubit.state.canConfirm, isTrue);
    expect(cubit.state.allSettled, isFalse);

    verify(() => getBalanceSummary(householdId: 'home', meUid: 'me')).called(1);
  });

  test('uses the supplied saved payment method', () async {
    await cubit.close();
    cubit = build(defaultMethod: SettlementMethod.bank);

    expect(cubit.state.method, SettlementMethod.bank);
  });

  test('credits cannot be selected as a manual settlement method', () async {
    await cubit.close();
    cubit = build(defaultMethod: SettlementMethod.credits);

    expect(cubit.state.method, SettlementMethod.momo);

    cubit.selectMethod(SettlementMethod.cash);
    cubit.selectMethod(SettlementMethod.credits);

    expect(cubit.state.method, SettlementMethod.cash);
  });

  test('selects known members and ignores invalid selections', () async {
    await ready();

    cubit.selectMember('grace');
    expect(cubit.state.selectedOtherUid, 'grace');
    expect(cubit.state.selectedBalance, -4000);

    cubit.selectMember('missing');
    cubit.selectMember('me');

    expect(cubit.state.selectedOtherUid, 'grace');
  });

  test('zero balances show all settled and disable confirmation', () async {
    await ready();

    balances.add(
      BalanceSummary(youAreOwed: 0, youOwe: 0, net: 0, byMember: {}),
    );

    expect(cubit.state.allSettled, isTrue);
    expect(cubit.state.canConfirm, isFalse);

    await cubit.confirm();

    verifyZeroInteractions(settleBetween);
  });

  test(
    'zero overall net does not hide balances with different people',
    () async {
      await ready();

      balances.add(
        BalanceSummary(
          youAreOwed: 4000,
          youOwe: 4000,
          net: 0,
          byMember: {'kevin': 4000, 'grace': -4000},
        ),
      );

      expect(cubit.state.allSettled, isFalse);
      expect(cubit.state.canConfirm, isTrue);
    },
  );

  test('confirms the selected member with the selected method', () async {
    await ready();

    cubit.selectMember('grace');
    cubit.selectMethod(SettlementMethod.bank);

    await cubit.confirm();

    expect(cubit.state.action, SettlementAction.success);
    expect(cubit.state.canConfirm, isFalse);

    verify(
      () => settleBetween(
        householdId: 'home',
        meUid: 'me',
        otherUid: 'grace',
        method: 'bank',
      ),
    ).called(1);
  });

  test('requires a selected member before confirmation', () async {
    await cubit.close();
    cubit = build(initialOtherUid: null);
    await ready();

    expect(cubit.state.canConfirm, isFalse);

    await cubit.confirm();

    verifyZeroInteractions(settleBetween);
  });

  test('failed confirmation keeps the selected member and method', () async {
    const failure = NetworkFailure();

    when(
      () => settleBetween(
        householdId: 'home',
        meUid: 'me',
        otherUid: 'kevin',
        method: 'cash',
      ),
    ).thenAnswer((_) async => Result<void>.failure(failure));

    await ready();
    cubit.selectMethod(SettlementMethod.cash);

    await cubit.confirm();

    expect(cubit.state.action, SettlementAction.failure);
    expect(cubit.state.actionFailure, same(failure));
    expect(cubit.state.selectedOtherUid, 'kevin');
    expect(cubit.state.method, SettlementMethod.cash);
    expect(cubit.state.canConfirm, isTrue);
  });

  test('blocks duplicate confirmation and edits during submission', () async {
    final gate = Completer<Result<void>>();

    when(
      () => settleBetween(
        householdId: 'home',
        meUid: 'me',
        otherUid: 'kevin',
        method: 'momo',
      ),
    ).thenAnswer((_) => gate.future);

    await ready();

    final confirming = cubit.confirm();

    expect(cubit.state.isSubmitting, isTrue);

    cubit.selectMember('grace');
    cubit.selectMethod(SettlementMethod.bank);
    await cubit.confirm();

    // A Firestore update may arrive before the write result returns.
    balances.add(
      BalanceSummary(
        youAreOwed: 0,
        youOwe: 4000,
        net: -4000,
        byMember: {'grace': -4000},
      ),
    );

    expect(cubit.state.isSubmitting, isTrue);
    expect(cubit.state.selectedOtherUid, 'kevin');
    expect(cubit.state.method, SettlementMethod.momo);

    gate.complete(Result<void>.success(null));
    await confirming;

    expect(cubit.state.action, SettlementAction.success);

    verify(
      () => settleBetween(
        householdId: 'home',
        meUid: 'me',
        otherUid: 'kevin',
        method: 'momo',
      ),
    ).called(1);
  });

  test('balance errors disable confirmation and retry can recover', () async {
    await ready();

    const failure = NetworkFailure();
    balances.addError(failure);

    expect(cubit.state.status, SettleStatus.failure);
    expect(cubit.state.failure, same(failure));
    expect(cubit.state.canConfirm, isFalse);

    await cubit.retry();
    balances.add(summary);

    expect(cubit.state.status, SettleStatus.loaded);
    expect(cubit.state.failure, isNull);
    expect(cubit.state.canConfirm, isTrue);
  });

  test('closing during confirmation ignores the late result', () async {
    final gate = Completer<Result<void>>();

    when(
      () => settleBetween(
        householdId: 'home',
        meUid: 'me',
        otherUid: 'kevin',
        method: 'momo',
      ),
    ).thenAnswer((_) => gate.future);

    await ready();

    final confirming = cubit.confirm();
    await cubit.close();

    expect(balances.hasListener, isFalse);

    gate.complete(Result<void>.success(null));
    await confirming;

    expect(cubit.isClosed, isTrue);
  });
}
