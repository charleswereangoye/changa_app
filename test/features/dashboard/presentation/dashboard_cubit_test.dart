// Owner: C - Person C (Expenses, Dashboard, Documentation)
// Description: Tests for DashboardCubit (balances, harmony, activity)

import 'dart:async';

import 'package:changa_app/features/activity/domain/entities/activity.dart';
import 'package:changa_app/features/chores/domain/entities/chore.dart';
import 'package:changa_app/features/dashboard/domain/entities/harmony_score.dart';
import 'package:changa_app/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:changa_app/features/debts/domain/entities/debt.dart';
import 'package:changa_app/features/debts/domain/entities/debt_status.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 11, 2, 12);

Debt _debt(String debtor, String creditor, int amount) => Debt(
  id: '$debtor-$creditor-$amount',
  expenseId: 'e1',
  debtorUid: debtor,
  creditorUid: creditor,
  amount: amount,
  creditsApplied: 0,
  status: DebtStatus.pending,
  createdAt: DateTime(2026, 11, 1),
);

Chore _doneOnTime() => Chore(
  id: 'c1',
  title: 'Dishes',
  difficulty: ChoreDifficulty.easy,
  assignedToUid: 'amara',
  dueDate: DateTime(2026, 10, 31),
  status: ChoreStatus.done,
  completedAt: DateTime(2026, 10, 31, 9),
  createdByUid: 'amara',
  createdAt: DateTime(2026, 10, 1),
);

Activity _activity(String id) => Activity(
  id: id,
  type: ActivityType.expenseAdded,
  actorUid: 'amara',
  amount: 12000,
  createdAt: DateTime(2026, 11, 1),
);

void main() {
  late StreamController<List<Debt>> pending;
  late StreamController<List<Debt>> debtsSince;
  late StreamController<List<Chore>> chores;
  late StreamController<List<Activity>> activity;
  late int pendingWatches;
  late DashboardCubit cubit;

  DashboardCubit build({
    WatchRecentActivityFn? watchActivity,
    WatchChoresFn? watchChores,
  }) {
    return DashboardCubit(
      watchPendingDebts: (_) {
        pendingWatches++;
        return pending.stream;
      },
      watchDebtsSince: (_, _) => debtsSince.stream,
      watchChores: watchChores ?? (_) => chores.stream,
      watchRecentActivity: watchActivity ?? (_) => activity.stream,
      clock: () => _now,
    );
  }

  setUp(() {
    pending = StreamController<List<Debt>>.broadcast();
    debtsSince = StreamController<List<Debt>>.broadcast();
    chores = StreamController<List<Chore>>.broadcast();
    activity = StreamController<List<Activity>>.broadcast();
    pendingWatches = 0;
    cubit = build();
  });

  tearDown(() async {
    await cubit.close();
    await pending.close();
    await debtsSince.close();
    await chores.close();
    await activity.close();
  });

  test(
    'no household: shows the no-household state and watches nothing',
    () async {
      await cubit.start(householdId: null, uid: 'amara');

      expect(cubit.state.hasHousehold, isFalse);
      expect(pendingWatches, 0);
      expect(pending.hasListener, isFalse);
    },
  );

  test('balance is summarised from pending debts for me', () async {
    await cubit.start(householdId: 'h1', uid: 'amara');
    expect(cubit.state.balanceStatus, DashboardSection.loading);

    pending.add([
      _debt('chloe', 'amara', 4000),
      _debt('amara', 'dan', 1500),
      _debt('chloe', 'dan', 999),
    ]);
    await pumpEventQueue();

    final balance = cubit.state.balance!;
    expect(cubit.state.balanceStatus, DashboardSection.ready);
    expect(balance.youAreOwed, 4000);
    expect(balance.youOwe, 1500);
    expect(balance.net, 2500);
    expect(balance.byMember, {'chloe': 4000, 'dan': -1500});
  });

  test('harmony is empty (a dash) when there is nothing to judge', () async {
    await cubit.start(householdId: 'h1', uid: 'amara');
    debtsSince.add(const []);
    chores.add(const []);
    await pumpEventQueue();

    expect(cubit.state.harmonyStatus, DashboardSection.ready);
    expect(cubit.state.harmony, isNull);
  });

  test('harmony waits for both chores and debts', () async {
    await cubit.start(householdId: 'h1', uid: 'amara');
    chores.add([_doneOnTime()]);
    await pumpEventQueue();
    expect(cubit.state.harmonyStatus, DashboardSection.loading);

    debtsSince.add(const []);
    await pumpEventQueue();
    expect(cubit.state.harmonyStatus, DashboardSection.ready);
    expect(cubit.state.harmony!.value, 100);
    expect(cubit.state.harmony!.tier, HarmonyTier.thriving);
  });

  test('recent activity is listed', () async {
    await cubit.start(householdId: 'h1', uid: 'amara');
    activity.add([_activity('a1'), _activity('a2')]);
    await pumpEventQueue();

    expect(cubit.state.activityStatus, DashboardSection.ready);
    expect(cubit.state.recentActivity.map((a) => a.id), ['a1', 'a2']);
  });

  test('a failing chores stream still lets payments score the house', () async {
    await cubit.start(householdId: 'h1', uid: 'amara');
    pending.add(const []);
    chores.addError(Exception('chores not ready'));
    debtsSince.add([_debt('chloe', 'amara', 4000)]);
    await pumpEventQueue();

    expect(cubit.state.balanceStatus, DashboardSection.ready);
    expect(cubit.state.harmonyStatus, DashboardSection.ready);
    expect(cubit.state.harmony!.choreScore, isNull);
    expect(cubit.state.harmony!.paymentScore, 100);
  });

  test('harmony fails only when both of its sources fail', () async {
    await cubit.start(householdId: 'h1', uid: 'amara');
    chores.addError(Exception('chores'));
    debtsSince.addError(Exception('debts'));
    await pumpEventQueue();

    expect(cubit.state.harmonyStatus, DashboardSection.failed);
    expect(cubit.state.harmony, isNull);
  });

  test('a source that throws on open only fails its own section', () async {
    await cubit.close();
    cubit = build(watchActivity: (_) => throw UnimplementedError());

    await cubit.start(householdId: 'h1', uid: 'amara');
    pending.add([_debt('chloe', 'amara', 4000)]);
    await pumpEventQueue();

    expect(cubit.state.activityStatus, DashboardSection.failed);
    expect(cubit.state.balanceStatus, DashboardSection.ready);
  });

  test('starting twice with the same household does not resubscribe', () async {
    await cubit.start(householdId: 'h1', uid: 'amara');
    await cubit.start(householdId: 'h1', uid: 'amara');

    expect(pendingWatches, 1);
  });

  test('retry resubscribes', () async {
    await cubit.start(householdId: 'h1', uid: 'amara');
    await cubit.retry();

    expect(pendingWatches, 2);
  });

  test('signing out cancels every subscription', () async {
    await cubit.start(householdId: 'h1', uid: 'amara');
    expect(pending.hasListener, isTrue);

    await cubit.start(householdId: null, uid: null);

    expect(cubit.state.hasHousehold, isFalse);
    expect(pending.hasListener, isFalse);
    expect(debtsSince.hasListener, isFalse);
    expect(chores.hasListener, isFalse);
    expect(activity.hasListener, isFalse);
  });

  test('closing the cubit cancels subscriptions', () async {
    await cubit.start(householdId: 'h1', uid: 'amara');
    await cubit.close();

    expect(pending.hasListener, isFalse);
    expect(activity.hasListener, isFalse);
  });

  test('a brand-new household reads as empty', () async {
    await cubit.start(householdId: 'h1', uid: 'amara');
    pending.add(const []);
    activity.add(const []);
    await pumpEventQueue();

    expect(cubit.state.isEmptyHousehold, isTrue);
  });
}
