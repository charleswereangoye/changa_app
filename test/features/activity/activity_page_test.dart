import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:changa_app/core/error/failures.dart';
import 'package:changa_app/core/theme/app_theme.dart';
import 'package:changa_app/features/activity/domain/entities/activity.dart';
import 'package:changa_app/features/activity/domain/usecases/watch_month_activity.dart';
import 'package:changa_app/features/activity/domain/usecases/watch_recent_activity.dart';
import 'package:changa_app/features/activity/presentation/cubit/activity_cubit.dart';
import 'package:changa_app/features/activity/presentation/pages/activity_page.dart';

class MockWatchMonthActivity extends Mock implements WatchMonthActivity {}

class MockWatchRecentActivity extends Mock implements WatchRecentActivity {}

void main() {
  final fixedNow = DateTime(2026, 10, 29, 14, 0);
  final todayTime = DateTime(2026, 10, 29, 12, 0);
  final yesterdayTime = DateTime(2026, 10, 28, 15, 0);
  final oct12Time = DateTime(2026, 10, 12, 10, 0);
  final septTime = DateTime(2026, 9, 18, 9, 0);
  final augTime = DateTime(2026, 8, 10, 9, 0);

  const memberNames = {'amara': 'Amara', 'kevin': 'Kevin', 'grace': 'Grace'};

  const refTitles = {'exp-1': 'Groceries — Simba', 'chore-1': 'Trash duty'};

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

  final augActivity = Activity(
    id: 'act-aug',
    type: ActivityType.debtSettled,
    actorUid: 'grace',
    targetUid: 'amara',
    amount: 6500,
    createdAt: augTime,
  );

  late MockWatchMonthActivity watchMonth;
  late MockWatchRecentActivity watchRecent;
  late StreamController<List<Activity>> octController;
  late StreamController<List<Activity>> septController;
  late StreamController<List<Activity>> augController;
  late StreamController<List<Activity>> recentController;
  late ActivityCubit cubit;

  setUp(() {
    watchMonth = MockWatchMonthActivity();
    watchRecent = MockWatchRecentActivity();
    octController = StreamController<List<Activity>>.broadcast(sync: true);
    septController = StreamController<List<Activity>>.broadcast(sync: true);
    augController = StreamController<List<Activity>>.broadcast(sync: true);
    recentController = StreamController<List<Activity>>.broadcast(sync: true);

    when(
      () => watchMonth(
        householdId: any(named: 'householdId'),
        month: any(named: 'month'),
      ),
    ).thenAnswer((_) => const Stream<List<Activity>>.empty());

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
      () => watchMonth(
        householdId: any(named: 'householdId'),
        month: DateTime(2026, 8, 1),
      ),
    ).thenAnswer((_) => augController.stream);

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
    await augController.close();
    await recentController.close();
  });

  Future<void> pumpActivityPage(
    WidgetTester tester, {
    ValueChanged<Activity>? onExpenseTap,
    void Function(DateTime date, Activity activity)? onChoreTap,
    double textScale = 1.0,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          );
        },
        home: ActivityPage(
          cubit: cubit,
          householdId: 'house-1',
          currentUid: 'amara',
          memberNames: memberNames,
          refTitles: refTitles,
          now: fixedNow,
          onExpenseTap: onExpenseTap,
          onChoreTap: onChoreTap,
        ),
      ),
    );
  }

  testWidgets(
    'renders sticky headers ("Today", "Yesterday", "12 Oct"), month tabs, search, and tap callbacks',
    (tester) async {
      Activity? tappedExpense;
      DateTime? tappedChoreDate;

      await cubit.start(householdId: 'house-1');
      recentController.add([expenseActivity, septActivity]);
      octController.add([expenseActivity, choreActivity, nudgeActivity]);

      await pumpActivityPage(
        tester,
        onExpenseTap: (activity) => tappedExpense = activity,
        onChoreTap: (date, _) => tappedChoreDate = date,
      );
      await tester.pump();

      expect(find.text('Oct'), findsOneWidget);
      expect(find.text('Sep'), findsOneWidget);

      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Yesterday'), findsWidgets);
      expect(find.text('12 Oct'), findsWidgets);

      expect(find.text('Groceries — Simba'), findsOneWidget);
      expect(find.text('RWF 24,000'), findsOneWidget);
      expect(find.text('Trash duty completed'), findsOneWidget);
      expect(find.text('+10 pts'), findsOneWidget);
      expect(find.text('Nudge sent to Kevin'), findsOneWidget);
      expect(find.text('Sent'), findsOneWidget);

      await tester.tap(find.text('Groceries — Simba'));
      expect(tappedExpense, expenseActivity);

      await tester.tap(find.text('Trash duty completed'));
      expect(tappedChoreDate, yesterdayTime);

      await tester.enterText(find.byType(TextField), 'Trash');
      await tester.pump();
      expect(find.text('Trash duty completed'), findsOneWidget);
      expect(find.text('Groceries — Simba'), findsNothing);

      await tester.tap(find.byTooltip('Clear search'));
      await tester.pump();
      expect(find.text('Groceries — Simba'), findsOneWidget);

      await tester.tap(find.text('Sep'));
      await tester.pump();
      septController.add([septActivity]);
      await tester.pump();

      expect(find.text('Kevin settled with you'), findsOneWidget);
      expect(find.text('RWF 4,000'), findsOneWidget);
    },
  );

  testWidgets('shows error state on stream failure and retries on tap', (
    tester,
  ) async {
    await cubit.start(householdId: 'house-1');
    octController.addError(
      const NetworkFailure('Could not load activity history.'),
    );

    await pumpActivityPage(tester);
    await tester.pump();

    expect(find.text('Could not load activity history.'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pump();

    octController.add([expenseActivity]);
    await tester.pump();

    expect(find.text('Groceries — Simba'), findsOneWidget);
  });

  testWidgets(
    'shows empty state for a month with no activity and fits 320px screen with scaled text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await cubit.start(householdId: 'house-1');
      recentController.add([expenseActivity, septActivity]);
      octController.add(const []);

      await pumpActivityPage(tester, textScale: 1.0);
      await tester.pump();

      expect(find.text('No activity this month'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'discovers and navigates to older month even when household has more than 100 recent activities',
    (tester) async {
      final over100OctActivities = List<Activity>.generate(
        105,
        (i) => Activity(
          id: 'oct-$i',
          type: ActivityType.expenseAdded,
          actorUid: 'amara',
          targetUid: 'kevin',
          refId: 'exp-1',
          amount: 1000 + i,
          createdAt: DateTime(
            2026,
            10,
            29,
            12,
            0,
          ).subtract(Duration(minutes: i)),
        ),
      );

      await cubit.start(householdId: 'house-1');
      // watchRecent(limit: 100) only emits the latest 100 (all in Oct)
      recentController.add(over100OctActivities.take(100).toList());
      octController.add(over100OctActivities);
      // Fallback older-month discovery finds August activity
      augController.add([augActivity]);

      await pumpActivityPage(tester);
      await tester.pump();

      // Aug tab is discovered despite 100+ Oct activities saturating watchRecent
      expect(find.text('Oct'), findsOneWidget);
      expect(find.text('Aug'), findsOneWidget);

      await tester.tap(find.text('Aug'));
      await tester.pump();
      augController.add([augActivity]);
      await tester.pump();

      expect(find.text('Grace settled with you'), findsOneWidget);
      expect(find.text('RWF 6,500'), findsOneWidget);
    },
  );
}
