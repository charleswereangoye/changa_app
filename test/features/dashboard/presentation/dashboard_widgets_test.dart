import 'package:changa_app/features/activity/domain/entities/activity.dart';
import 'package:changa_app/features/dashboard/domain/entities/harmony_score.dart';
import 'package:changa_app/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:changa_app/features/dashboard/presentation/widgets/balance_summary_card.dart';
import 'package:changa_app/features/dashboard/presentation/widgets/dashboard_empty_state.dart';
import 'package:changa_app/features/dashboard/presentation/widgets/harmony_card.dart';
import 'package:changa_app/features/dashboard/presentation/widgets/harmony_explainer_sheet.dart';
import 'package:changa_app/features/dashboard/presentation/widgets/quick_actions.dart';
import 'package:changa_app/features/dashboard/presentation/widgets/recent_activity_list.dart';
import 'package:changa_app/features/debts/domain/entities/balance_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _show(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
  await tester.pumpAndSettle();
}

const _names = {'amara': 'Amara', 'chloe': 'Chloe', 'dan': 'Dan'};

void main() {
  group('HarmonyCard', () {
    testWidgets('shows the tier of the score', (tester) async {
      await _show(
        tester,
        HarmonyCard(
          status: DashboardSection.ready,
          score: const HarmonyScore(value: 85, tier: HarmonyTier.thriving),
          onInfo: () {},
        ),
      );

      expect(find.text('Thriving'), findsOneWidget);
      expect(find.text('85'), findsOneWidget);
    });

    testWidgets('shows a dash and a hint when there is no data', (
      tester,
    ) async {
      await _show(
        tester,
        HarmonyCard(status: DashboardSection.ready, score: null, onInfo: () {}),
      );

      expect(find.text('Not enough data yet'), findsOneWidget);
      expect(find.text('—'), findsOneWidget);
    });

    testWidgets('loading and failed have their own text', (tester) async {
      await _show(
        tester,
        HarmonyCard(
          status: DashboardSection.loading,
          score: null,
          onInfo: () {},
        ),
      );
      expect(find.text('Loading...'), findsOneWidget);

      await _show(
        tester,
        HarmonyCard(
          status: DashboardSection.failed,
          score: null,
          onInfo: () {},
        ),
      );
      expect(find.text("Couldn't load the score"), findsOneWidget);
    });

    testWidgets('the info button calls back', (tester) async {
      var taps = 0;
      await _show(
        tester,
        HarmonyCard(
          status: DashboardSection.ready,
          score: null,
          onInfo: () => taps++,
        ),
      );

      await tester.tap(find.byKey(const Key('harmony-info')));
      expect(taps, 1);
    });
  });

  testWidgets('HarmonyExplainerSheet explains the tiers', (tester) async {
    await _show(tester, const HarmonyExplainerSheet());

    expect(find.text('How Harmony works'), findsOneWidget);
    expect(find.text('Thriving'), findsOneWidget);
    expect(find.text('Needs attention'), findsOneWidget);
  });

  group('BalanceSummaryCard', () {
    final summary = BalanceSummary(
      youAreOwed: 4000,
      youOwe: 1500,
      net: 2500,
      byMember: const {'chloe': 4000, 'dan': -1500},
    );

    testWidgets('shows totals and who owes whom', (tester) async {
      await _show(
        tester,
        BalanceSummaryCard(
          status: DashboardSection.ready,
          summary: summary,
          names: _names,
          onRetry: () {},
        ),
      );

      expect(find.text('RWF 4,000'), findsNWidgets(2));
      expect(find.text('RWF 1,500'), findsNWidgets(2));
      expect(find.text('Chloe'), findsOneWidget);
      expect(find.text('Dan'), findsOneWidget);
      expect(find.text('owes you'), findsOneWidget);
      expect(find.text('you owe'), findsOneWidget);
    });

    testWidgets('tapping a person reports their uid', (tester) async {
      String? tapped;
      await _show(
        tester,
        BalanceSummaryCard(
          status: DashboardSection.ready,
          summary: summary,
          names: _names,
          onRetry: () {},
          onMemberTap: (uid) => tapped = uid,
        ),
      );

      await tester.tap(find.byKey(const Key('balance-row-chloe')));
      expect(tapped, 'chloe');
    });

    testWidgets('no debts reads as settled up', (tester) async {
      await _show(
        tester,
        BalanceSummaryCard(
          status: DashboardSection.ready,
          summary: BalanceSummary(
            youAreOwed: 0,
            youOwe: 0,
            net: 0,
            byMember: const {},
          ),
          names: _names,
          onRetry: () {},
        ),
      );

      expect(find.byKey(const Key('balance-settled')), findsOneWidget);
    });

    testWidgets('failed shows a retry button', (tester) async {
      var retries = 0;
      await _show(
        tester,
        BalanceSummaryCard(
          status: DashboardSection.failed,
          summary: null,
          names: _names,
          onRetry: () => retries++,
        ),
      );

      await tester.tap(find.byKey(const Key('balance-retry')));
      expect(retries, 1);
    });
  });

  testWidgets('QuickActions report each tap', (tester) async {
    final taps = <String>[];
    await _show(
      tester,
      QuickActions(
        onAddExpense: () => taps.add('expense'),
        onSettleUp: () => taps.add('settle'),
        onAddChore: () => taps.add('chore'),
      ),
    );

    await tester.tap(find.byKey(const Key('quick-add-expense')));
    await tester.tap(find.byKey(const Key('quick-settle-up')));
    await tester.tap(find.byKey(const Key('quick-add-chore')));

    expect(taps, ['expense', 'settle', 'chore']);
  });

  group('RecentActivityList', () {
    final now = DateTime(2026, 11, 2, 12);

    testWidgets('writes readable lines with You and names', (tester) async {
      await _show(
        tester,
        RecentActivityList(
          status: DashboardSection.ready,
          items: [
            Activity(
              id: 'a1',
              type: ActivityType.expenseAdded,
              actorUid: 'amara',
              amount: 12000,
              createdAt: DateTime(2026, 11, 2, 10),
            ),
            Activity(
              id: 'a2',
              type: ActivityType.nudgeSent,
              actorUid: 'chloe',
              targetUid: 'amara',
              createdAt: DateTime(2026, 11, 1, 9),
            ),
          ],
          names: _names,
          currentUid: 'amara',
          onSeeAll: () {},
          now: now,
        ),
      );

      expect(find.text('You added an expense of RWF 12,000'), findsOneWidget);
      expect(find.text('Chloe sent you a friendly nudge'), findsOneWidget);
      expect(find.text('2 h ago'), findsOneWidget);
      expect(find.text('Yesterday'), findsOneWidget);
    });

    testWidgets('empty shows a hint and See all calls back', (tester) async {
      var taps = 0;
      await _show(
        tester,
        RecentActivityList(
          status: DashboardSection.ready,
          items: const [],
          names: _names,
          currentUid: 'amara',
          onSeeAll: () => taps++,
          now: now,
        ),
      );

      expect(find.byKey(const Key('activity-empty')), findsOneWidget);
      await tester.tap(find.byKey(const Key('activity-see-all')));
      expect(taps, 1);
    });

    test('unknown people read as a housemate', () {
      final text = RecentActivityList.describe(
        Activity(
          id: 'a3',
          type: ActivityType.memberJoined,
          actorUid: 'ghost',
          createdAt: DateTime(2026, 11, 2),
        ),
        currentUid: 'amara',
        names: _names,
      );
      expect(text, 'A housemate joined the household');
    });
  });

  testWidgets('DashboardEmptyState shows both actions', (tester) async {
    var primary = 0;
    var secondary = 0;
    await _show(
      tester,
      DashboardEmptyState(
        title: 'Join your household',
        message: 'Create one or join with a PIN.',
        primaryLabel: 'Create household',
        onPrimary: () => primary++,
        secondaryLabel: 'Join with a PIN',
        onSecondary: () => secondary++,
      ),
    );

    await tester.tap(find.byKey(const Key('empty-primary')));
    await tester.tap(find.byKey(const Key('empty-secondary')));
    expect(primary, 1);
    expect(secondary, 1);
  });
}
