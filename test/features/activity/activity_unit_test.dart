import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:changa_app/core/constants/firestore_paths.dart';
import 'package:changa_app/core/error/failures.dart';
import 'package:changa_app/features/activity/data/activity_writer.dart';
import 'package:changa_app/features/activity/data/datasources/activity_remote_datasource.dart';
import 'package:changa_app/features/activity/data/repositories/activity_repository_impl.dart';
import 'package:changa_app/features/activity/domain/activity_message_builder.dart';
import 'package:changa_app/features/activity/domain/entities/activity.dart';
import 'package:changa_app/features/activity/domain/usecases/watch_month_activity.dart';
import 'package:changa_app/features/activity/domain/usecases/watch_recent_activity.dart';
import 'package:changa_app/features/activity/presentation/cubit/activity_cubit.dart';

class MockWatchMonthActivity extends Mock implements WatchMonthActivity {}

class MockWatchRecentActivity extends Mock implements WatchRecentActivity {}

void main() {
  final fixedNow = DateTime(2026, 10, 29, 14, 0);
  final todayTime = DateTime(2026, 10, 29, 12, 0);
  final yesterdayTime = DateTime(2026, 10, 28, 15, 0);
  final oct12Time = DateTime(2026, 10, 12, 10, 0);
  final septTime = DateTime(2026, 9, 18, 9, 0);

  const memberNames = {'amara': 'Amara', 'kevin': 'Kevin', 'grace': 'Grace'};

  final expenseActivity = Activity(
    id: 'act-1',
    type: ActivityType.expenseAdded,
    actorUid: 'amara',
    targetUid: 'kevin',
    refId: 'exp-1',
    amount: 24000,
    createdAt: todayTime,
  );

  final choreActivity = Activity(
    id: 'act-2',
    type: ActivityType.choreCompleted,
    actorUid: 'grace',
    refId: 'chore-1',
    amount: 10,
    createdAt: yesterdayTime,
  );

  final nudgeActivity = Activity(
    id: 'act-3',
    type: ActivityType.nudgeSent,
    actorUid: 'amara',
    targetUid: 'kevin',
    createdAt: oct12Time,
  );

  final septActivity = Activity(
    id: 'act-4',
    type: ActivityType.debtSettled,
    actorUid: 'kevin',
    targetUid: 'amara',
    amount: 4000,
    createdAt: septTime,
  );

   
  // 1. DATA LAYER: ActivityRemoteDataSourceImpl & ActivityRepositoryImpl
  group('ActivityRemoteDataSourceImpl & ActivityRepositoryImpl', () {
    late FakeFirebaseFirestore firestore;
    late ActivityRemoteDataSourceImpl dataSource;
    late ActivityRepositoryImpl repository;
    late ActivityWriter writer;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      dataSource = ActivityRemoteDataSourceImpl(firestore: firestore);
      repository = ActivityRepositoryImpl(remoteDataSource: dataSource);
      writer = ActivityWriter(firestore: firestore);
    });

    Future<void> seedActivity({
      required String householdId,
      required String id,
      required ActivityType type,
      required String actorUid,
      required DateTime createdAt,
      String? targetUid,
      String? refId,
      int? amount,
    }) async {
      await firestore.doc(FirestorePaths.activity(householdId, id)).set({
        ActivityFields.type: type.name,
        ActivityFields.actorUid: actorUid,
        ActivityFields.targetUid: ?targetUid,
        ActivityFields.refId: ?refId,
        ActivityFields.amount: ?amount,
        ActivityFields.createdAt: Timestamp.fromDate(createdAt),
      });
    }

    test(
      'watchRecent returns activities ordered newest first and respects limit',
      () async {
        for (var i = 1; i <= 7; i++) {
          await seedActivity(
            householdId: 'house-1',
            id: 'act-$i',
            type: ActivityType.expenseAdded,
            actorUid: 'amara',
            amount: i * 1000,
            createdAt: DateTime(2026, 10, i, 12, 0),
          );
        }

        final recent = await repository.watchRecent('house-1', limit: 5).first;

        expect(recent, hasLength(5));
        expect(recent.map((a) => a.id).toList(), [
          'act-7',
          'act-6',
          'act-5',
          'act-4',
          'act-3',
        ]);
      },
    );

    test('watchMonth returns only activities inside the requested month boundaries', () async {
      // Sept 30 at 23:59:59 (excluded from Oct)
      await seedActivity(
        householdId: 'house-1',
        id: 'sept-end',
        type: ActivityType.memberJoined,
        actorUid: 'kevin',
        createdAt: DateTime(2026, 9, 30, 23, 59, 59),
      );
      // Oct 1 at 00:00:00 (included in Oct)
      await seedActivity(
        householdId: 'house-1',
        id: 'oct-start',
        type: ActivityType.expenseAdded,
        actorUid: 'amara',
        amount: 12000,
        createdAt: DateTime(2026, 10, 1, 0, 0, 0),
      );
      // Oct 31 at 23:59:59 (included in Oct)
      await seedActivity(
        householdId: 'house-1',
        id: 'oct-end',
        type: ActivityType.choreCompleted,
        actorUid: 'grace',
        amount: 10,
        createdAt: DateTime(2026, 10, 31, 23, 59, 59),
      );
      // Nov 1 at 00:00:00 (excluded from Oct)
      await seedActivity(
        householdId: 'house-1',
        id: 'nov-start',
        type: ActivityType.nudgeSent,
        actorUid: 'amara',
        targetUid: 'kevin',
        createdAt: DateTime(2026, 11, 1, 0, 0, 0),
      );

      final octItems = await repository
          .watchMonth('house-1', DateTime(2026, 10, 15))
          .first;

      expect(octItems.map((a) => a.id).toList(), ['oct-end', 'oct-start']);
    });

    test('ignores malformed documents with unknown ActivityType without crashing stream', () async {
      await firestore.doc(FirestorePaths.activity('house-1', 'bad-doc')).set({
        ActivityFields.type: 'futureUnknownEvent',
        ActivityFields.actorUid: 'amara',
        ActivityFields.createdAt: Timestamp.fromDate(todayTime),
      });

      final batch = firestore.batch();
      writer.addToBatch(
        batch,
        householdId: 'house-1',
        type: ActivityType.memberJoined,
        actorUid: 'amara',
      );
      await batch.commit();

      final items = await repository.watchRecent('house-1', limit: 5).first;
      expect(items, hasLength(1));
      expect(items.first.type, ActivityType.memberJoined);
    });

    test('returns empty list immediately for blank householdId', () async {
      expect(await repository.watchRecent('   ').first, isEmpty);
      expect(
        await repository.watchMonth('', DateTime(2026, 10, 1)).first,
        isEmpty,
      );
    });
  });


  // 2. DOMAIN LAYER: ActivityMessageBuilder
  group('ActivityMessageBuilder', () {
    test('formats expenseAdded with itemTitle and RWF amount per B10 spec', () {
      final text = ActivityMessageBuilder.build(
        expenseActivity,
        memberNames,
        itemTitle: 'Groceries',
      );
      expect(text, 'Amara added Groceries, RWF 24,000');
    });

    test('resolves itemTitle from refTitles map when itemTitle is not passed directly', () {
      final text = ActivityMessageBuilder.build(
        expenseActivity,
        memberNames,
        refTitles: const {'exp-1': 'Electricity Bill'},
      );
      expect(text, 'Amara added Electricity Bill, RWF 24,000');
    });

    test('formats all 9 ActivityType variants cleanly', () {
      expect(
        ActivityMessageBuilder.build(
          Activity(
            id: '1',
            type: ActivityType.expenseDeleted,
            actorUid: 'amara',
            amount: 15000,
            createdAt: todayTime,
          ),
          memberNames,
          itemTitle: 'Internet',
        ),
        'Amara deleted Internet, RWF 15,000',
      );

      expect(
        ActivityMessageBuilder.build(septActivity, memberNames),
        'Kevin settled with Amara, RWF 4,000',
      );

      expect(
        ActivityMessageBuilder.build(
          choreActivity,
          memberNames,
          itemTitle: 'Sweep living room',
        ),
        'Grace completed Sweep living room (+10 pts)',
      );

      expect(
        ActivityMessageBuilder.build(
          Activity(
            id: '2',
            type: ActivityType.memberJoined,
            actorUid: 'grace',
            createdAt: todayTime,
          ),
          memberNames,
        ),
        'Grace joined the household',
      );

      expect(
        ActivityMessageBuilder.build(
          Activity(
            id: '3',
            type: ActivityType.memberRemoved,
            actorUid: 'amara',
            targetUid: 'kevin',
            createdAt: todayTime,
          ),
          memberNames,
        ),
        'Kevin was removed from the household',
      );

      expect(
        ActivityMessageBuilder.build(
          Activity(
            id: '4',
            type: ActivityType.swapRequested,
            actorUid: 'grace',
            targetUid: 'kevin',
            createdAt: todayTime,
          ),
          memberNames,
        ),
        'Grace requested a chore swap with Kevin',
      );

      expect(
        ActivityMessageBuilder.build(
          Activity(
            id: '5',
            type: ActivityType.swapAccepted,
            actorUid: 'kevin',
            targetUid: 'grace',
            createdAt: todayTime,
          ),
          memberNames,
        ),
        'Kevin accepted a chore swap with Grace',
      );

      expect(
        ActivityMessageBuilder.build(nudgeActivity, memberNames),
        'Nudge sent to Kevin',
      );
    });

    test('uses You / you when currentUid matches actorUid or targetUid', () {
      expect(
        ActivityMessageBuilder.build(
          septActivity,
          memberNames,
          currentUid: 'kevin',
        ),
        'You settled with Amara, RWF 4,000',
      );
      expect(
        ActivityMessageBuilder.build(
          septActivity,
          memberNames,
          currentUid: 'amara',
        ),
        'Kevin settled with you, RWF 4,000',
      );
    });

    test('falls back to Former member when UID is absent from memberNames', () {
      final unknownActor = Activity(
        id: 'unknown',
        type: ActivityType.expenseAdded,
        actorUid: 'deleted-user',
        amount: 5000,
        createdAt: todayTime,
      );
      expect(
        ActivityMessageBuilder.build(unknownActor, memberNames),
        'Former member added an expense, RWF 5,000',
      );
    });

    test('formats card subtitle and trailing badges matching Figma', () {
      expect(
        ActivityMessageBuilder.formatCardSubtitle(
          expenseActivity,
          memberNames,
          now: fixedNow,
        ),
        'Paid by Amara · 2h ago',
      );
      expect(
        ActivityMessageBuilder.formatCardSubtitle(
          choreActivity,
          memberNames,
          currentUid: 'grace',
          now: fixedNow,
        ),
        'By you · Yesterday',
      );
      expect(
        ActivityMessageBuilder.formatTrailingBadge(expenseActivity),
        'RWF 24,000',
      );
      expect(
        ActivityMessageBuilder.formatTrailingBadge(choreActivity),
        '+10 pts',
      );
      expect(ActivityMessageBuilder.formatTrailingBadge(nudgeActivity), 'Sent');
    });
  });

  
  // 3. PRESENTATION LAYER: ActivityCubit
  group('ActivityCubit', () {
    late MockWatchMonthActivity watchMonth;
    late MockWatchRecentActivity watchRecent;
    late StreamController<List<Activity>> octController;
    late StreamController<List<Activity>> septController;
    late StreamController<List<Activity>> recentController;
    late ActivityCubit cubit;

    setUp(() {
      watchMonth = MockWatchMonthActivity();
      watchRecent = MockWatchRecentActivity();
      octController = StreamController<List<Activity>>.broadcast(sync: true);
      septController = StreamController<List<Activity>>.broadcast(sync: true);
      recentController = StreamController<List<Activity>>.broadcast(sync: true);

      when(
        () => watchMonth(
          householdId: any(named: 'householdId'),
          month: DateTime(2026, 10, 1),
        ),
      ).thenAnswer((_) => octController.stream);

      when(
        () => watchMonth(
          householdId: any(named: 'householdId'),
          month: DateTime(2026, 9, 1),
        ),
      ).thenAnswer((_) => septController.stream);

      when(
        () => watchRecent(
          householdId: any(named: 'householdId'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) => recentController.stream);

      cubit = ActivityCubit(
        watchMonthActivity: watchMonth,
        watchRecentActivity: watchRecent,
        clock: () => fixedNow,
      );
    });

    tearDown(() async {
      if (!cubit.isClosed) {
        await cubit.close();
      }
      await octController.close();
      await septController.close();
      await recentController.close();
    });

    test(
      'starts in initial state and selects current month on start()',
      () async {
        expect(cubit.state, isA<ActivityStateInitial>());

        await cubit.start(householdId: 'house-1');
        expect(cubit.state, isA<ActivityStateLoading>());

        recentController.add([expenseActivity, septActivity]);
        octController.add([expenseActivity, choreActivity, nudgeActivity]);

        final loaded = cubit.state as ActivityStateLoaded;
        expect(loaded.selectedMonth, DateTime(2026, 10, 1));
        // Only months with data (Oct and Sep) are in availableMonths
        expect(loaded.availableMonths, [
          DateTime(2026, 10, 1),
          DateTime(2026, 9, 1),
        ]);
        expect(loaded.activities, [
          expenseActivity,
          choreActivity,
          nudgeActivity,
        ]);
        expect(loaded.recentActivities, [expenseActivity, septActivity]);
      },
    );

    test(
      'search filters loaded activities by member name, item title, or amount',
      () async {
        await cubit.start(householdId: 'house-1');
        octController.add([expenseActivity, choreActivity, nudgeActivity]);

        cubit.search('Grace');
        var loaded = cubit.state as ActivityStateLoaded;
        expect(loaded.filterActivities(memberNames: memberNames), [
          choreActivity,
        ]);

        cubit.search('Simba');
        loaded = cubit.state as ActivityStateLoaded;
        expect(
          loaded.filterActivities(
            memberNames: memberNames,
            refTitles: const {'exp-1': 'Groceries — Simba'},
          ),
          [expenseActivity],
        );

        cubit.search('24,000');
        loaded = cubit.state as ActivityStateLoaded;
        expect(loaded.filterActivities(memberNames: memberNames), [
          expenseActivity,
        ]);
      },
    );

    test(
      'selectMonth switches month stream and retains discovered months',
      () async {
        await cubit.start(householdId: 'house-1');
        recentController.add([expenseActivity, septActivity]);
        octController.add([expenseActivity]);

        await cubit.selectMonth(DateTime(2026, 9, 15));
        expect(cubit.state, isA<ActivityStateLoading>());

        septController.add([septActivity]);
        final loaded = cubit.state as ActivityStateLoaded;
        expect(loaded.selectedMonth, DateTime(2026, 9, 1));
        expect(loaded.activities, [septActivity]);
        expect(loaded.availableMonths, [
          DateTime(2026, 10, 1),
          DateTime(2026, 9, 1),
        ]);
      },
    );

    test('emits failure on stream error and recovers on retry()', () async {
      await cubit.start(householdId: 'house-1');
      octController.addError(const NetworkFailure('Offline'));

      final failed = cubit.state as ActivityStateFailure;
      expect(failed.failure, isA<NetworkFailure>());

      await cubit.retry();
      expect(cubit.state, isA<ActivityStateLoading>());

      octController.add([expenseActivity]);
      expect(cubit.state, isA<ActivityStateLoaded>());
    });

    test('household switch and sign-out immediately clear previous session data', () async {
      await cubit.start(householdId: 'house-1');
      octController.add([expenseActivity]);
      expect(cubit.state, isA<ActivityStateLoaded>());

      // Switching to another household immediately replaces Loaded with Loading
      final switching = cubit.start(householdId: 'house-2');
      expect(cubit.state, isA<ActivityStateLoading>());
      await switching;

      // Signing out / leaving household resets to Initial and cancels streams
      await cubit.start(householdId: null);
      expect(cubit.state, isA<ActivityStateInitial>());
      expect(octController.hasListener, isFalse);
    });

    test(
      'watchRecentForDashboard delegates to WatchRecentActivity with limit 5',
      () async {
        final stream = cubit.watchRecentForDashboard('house-1');
        final sub = stream.listen((_) {});
        addTearDown(sub.cancel);

        verify(() => watchRecent(householdId: 'house-1', limit: 5)).called(1);
      },
    );
  });
}
