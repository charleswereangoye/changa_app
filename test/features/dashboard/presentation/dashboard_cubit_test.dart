// Owner: C - Person C (Expenses, Dashboard, Documentation)
// Description: Tests for DashboardCubit (balances, harmony, activity)

import 'dart:async';

import 'package:changa_app/core/enums/settlement_method.dart';
import 'package:changa_app/features/activity/domain/entities/activity.dart';
import 'package:changa_app/features/chores/domain/entities/chore.dart';
import 'package:changa_app/features/dashboard/domain/entities/harmony_score.dart';
import 'package:changa_app/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:changa_app/features/debts/domain/entities/debt.dart';
import 'package:changa_app/features/debts/domain/entities/debt_status.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 11, 2, 12);

Debt _debt(
  String debtor,
  String creditor,
  int amount, {
  String? id,
  DateTime? created,
  DebtStatus status = DebtStatus.pending,
  DateTime? settledAt,
  SettlementMethod? method,
}) => Debt(
  id: id ?? '$debtor-$creditor-$amount',
  expenseId: 'e1',
  debtorUid: debtor,
  creditorUid: creditor,
  amount: amount,
  creditsApplied: 0,
  status: status,
  settlementMethod: method,
  settledAt: settledAt,
  createdAt: created ?? DateTime(2026, 11, 1),
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

  /// Gives every Harmony source its first value.
  Future<void> loadAll({
    List<Debt> pendingDebts = const [],
    List<Debt> recentDebts = const [],
    List<Chore> choreList = const [],
  }) async {
    pending.add(pendingDebts);
    debtsSince.add(recentDebts);
    chores.add(choreList);
    await pumpEventQueue();
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

  test('harmony is empty (a dash) when there is genuinely no data', () async {
    await cubit.start(householdId: 'h1', uid: 'amara');
    await loadAll();

    expect(cubit.state.harmonyStatus, DashboardSection.ready);
    expect(cubit.state.harmony, isNull);
  });

  test('harmony waits for all three sources', () async {
    await cubit.start(householdId: 'h1', uid: 'amara');
    chores.add([_doneOnTime()]);
    debtsSince.add(const []);
    await pumpEventQueue();
    expect(cubit.state.harmonyStatus, DashboardSection.loading);

    pending.add(const []);
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

  group('combining pending and recent debts', () {
    test('a 40-day-old unpaid debt still reduces the score', () async {
      // Older than the 30-day window, so only the pending stream has it.
      final old = _debt(
        'chloe',
        'amara',
        4000,
        id: 'old',
        created: _now.subtract(const Duration(days: 40)),
      );

      await cubit.start(householdId: 'h1', uid: 'amara');
      await loadAll(pendingDebts: [old]);

      final harmony = cubit.state.harmony!;
      expect(harmony.paymentScore, 0);
      expect(harmony.value, 0);
      expect(harmony.tier, HarmonyTier.needsAttention);
      expect(harmony.choreScore, isNull);
    });

    test('the same debt in both streams is counted once', () async {
      final unpaid = _debt(
        'chloe',
        'amara',
        4000,
        id: 'd1',
        created: DateTime(2026, 10, 23, 12), // 10 days old, still unpaid
      );
      final paidOnTime = _debt(
        'dan',
        'amara',
        2000,
        id: 'd2',
        created: DateTime(2026, 10, 30),
        status: DebtStatus.settled,
        settledAt: DateTime(2026, 10, 31),
        method: SettlementMethod.cash,
      );

      await cubit.start(householdId: 'h1', uid: 'amara');
      await loadAll(pendingDebts: [unpaid], recentDebts: [unpaid, paidOnTime]);

      // Two debts, one healthy: 50. Counting d1 twice would give 33.
      expect(cubit.state.harmony!.paymentScore, 50);
    });

    test('a settled copy wins when both streams carry the debt', () async {
      final stale = _debt(
        'chloe',
        'amara',
        4000,
        id: 'd1',
        created: DateTime(2026, 10, 23, 12),
      );
      final settled = _debt(
        'chloe',
        'amara',
        4000,
        id: 'd1',
        created: DateTime(2026, 10, 23, 12),
        status: DebtStatus.settled,
        settledAt: DateTime(2026, 10, 24),
        method: SettlementMethod.cash,
      );

      await cubit.start(householdId: 'h1', uid: 'amara');
      await loadAll(pendingDebts: [stale], recentDebts: [settled]);

      expect(cubit.state.harmony!.paymentScore, 100);
    });

    test('recomputes when either stream changes', () async {
      final old = _debt(
        'chloe',
        'amara',
        4000,
        id: 'old',
        created: _now.subtract(const Duration(days: 40)),
      );
      final paidOnTime = _debt(
        'dan',
        'amara',
        2000,
        id: 'd2',
        created: DateTime(2026, 10, 30),
        status: DebtStatus.settled,
        settledAt: DateTime(2026, 10, 31),
        method: SettlementMethod.cash,
      );

      await cubit.start(householdId: 'h1', uid: 'amara');
      await loadAll();
      expect(cubit.state.harmony, isNull);

      pending.add([old]);
      await pumpEventQueue();
      expect(cubit.state.harmony!.value, 0);

      debtsSince.add([paidOnTime]);
      await pumpEventQueue();
      expect(cubit.state.harmony!.value, 50);

      pending.add(const []);
      await pumpEventQueue();
      expect(cubit.state.harmony!.value, 100);
    });
  });

  group('unavailable data is not the same as empty data', () {
    test(
      'chores failing makes Harmony unavailable, then it recovers',
      () async {
        await cubit.start(householdId: 'h1', uid: 'amara');
        pending.add(const []);
        debtsSince.add([_debt('chloe', 'amara', 4000)]);
        activity.add([_activity('a1')]);
        chores.addError(Exception('chores down'));
        await pumpEventQueue();

        // No score from the remaining sources (it would have been 100).
        expect(cubit.state.harmonyStatus, DashboardSection.failed);
        expect(cubit.state.harmony, isNull);
        // Everything else keeps working.
        expect(cubit.state.balanceStatus, DashboardSection.ready);
        expect(cubit.state.activityStatus, DashboardSection.ready);
        expect(cubit.state.recentActivity, hasLength(1));

        chores.add(const []);
        await pumpEventQueue();
        expect(cubit.state.harmonyStatus, DashboardSection.ready);
        expect(cubit.state.harmony!.paymentScore, 100);
      },
    );

    test(
      'the recent-debts stream failing is unavailable, then recovers',
      () async {
        await cubit.start(householdId: 'h1', uid: 'amara');
        await loadAll();
        expect(cubit.state.harmonyStatus, DashboardSection.ready);

        debtsSince.addError(Exception('debts down'));
        await pumpEventQueue();
        expect(cubit.state.harmonyStatus, DashboardSection.failed);
        expect(cubit.state.harmony, isNull);
        expect(cubit.state.balanceStatus, DashboardSection.ready);

        debtsSince.add(const []);
        await pumpEventQueue();
        expect(cubit.state.harmonyStatus, DashboardSection.ready);
      },
    );

    test(
      'pending debts failing hits balance and Harmony, not activity',
      () async {
        await cubit.start(householdId: 'h1', uid: 'amara');
        await loadAll();

        pending.addError(Exception('pending down'));
        activity.add([_activity('a1')]);
        await pumpEventQueue();

        expect(cubit.state.balanceStatus, DashboardSection.failed);
        expect(cubit.state.harmonyStatus, DashboardSection.failed);
        expect(cubit.state.activityStatus, DashboardSection.ready);

        pending.add([_debt('chloe', 'amara', 4000)]);
        await pumpEventQueue();

        expect(cubit.state.balanceStatus, DashboardSection.ready);
        expect(cubit.state.balance!.youAreOwed, 4000);
        expect(cubit.state.harmonyStatus, DashboardSection.ready);
        expect(cubit.state.harmony!.paymentScore, 100);
      },
    );

    test(
      'a recovered source goes back to loading until the rest arrive',
      () async {
        await cubit.start(householdId: 'h1', uid: 'amara');
        pending.addError(Exception('pending down'));
        await pumpEventQueue();
        expect(cubit.state.harmonyStatus, DashboardSection.failed);

        pending.add(const []);
        await pumpEventQueue();
        expect(cubit.state.harmonyStatus, DashboardSection.loading);

        debtsSince.add(const []);
        chores.add(const []);
        await pumpEventQueue();
        expect(cubit.state.harmonyStatus, DashboardSection.ready);
      },
    );

    test(
      'a chores source that throws on open is unavailable until retry',
      () async {
        var choresBroken = true;
        await cubit.close();
        cubit = build(
          watchChores: (_) {
            if (choresBroken) throw StateError('chores not ready');
            return chores.stream;
          },
        );

        await cubit.start(householdId: 'h1', uid: 'amara');
        pending.add(const []);
        debtsSince.add(const []);
        await pumpEventQueue();
        expect(cubit.state.harmonyStatus, DashboardSection.failed);

        choresBroken = false;
        await cubit.retry();
        await loadAll();
        expect(cubit.state.harmonyStatus, DashboardSection.ready);
      },
    );
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
