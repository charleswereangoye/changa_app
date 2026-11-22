import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:changa_app/core/theme/app_theme.dart';
import 'package:changa_app/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:changa_app/features/dashboard/presentation/widgets/balance_summary_card.dart';
import 'package:changa_app/features/debts/domain/entities/balance_summary.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final loader = FontLoader('Poppins')
      ..addFont(rootBundle.load('assets/fonts/Poppins-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Poppins-SemiBold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Poppins-Bold.ttf'));

    await loader.load();
  });

  Future<void> show(
    WidgetTester tester, {
    required Size size,
    required BalanceSummary summary,
    required VoidCallback onSettleUp,
    required ValueChanged<String> onMemberTap,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(4)),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: BalanceSummaryCard(
                status: DashboardSection.ready,
                summary: summary,
                names: const {
                  'jean': 'Jean Baptiste',
                  'grace': 'Grace Uwimana',
                },
                onRetry: () {},
                onSettleUp: onSettleUp,
                onMemberTap: onMemberTap,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  for (final size in [const Size(320, 640), const Size(640, 320)]) {
    testWidgets(
      'zero balances fit large text at ${size.width}x${size.height}',
      (tester) async {
        var settleTaps = 0;

        await show(
          tester,
          size: size,
          summary: BalanceSummary(
            youAreOwed: 0,
            youOwe: 0,
            net: 0,
            byMember: {},
          ),
          onSettleUp: () => settleTaps++,
          onMemberTap: (_) {},
        );

        expect(find.text('RWF 0'), findsNWidgets(2));
        expect(find.text('All settled up'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tapVisible(tester, find.byKey(const Key('balance-settle-up')));

        expect(settleTaps, 1);
        expect(tester.takeException(), isNull);

        await tester.ensureVisible(find.byKey(const Key('balance-settled')));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'member balances remain usable at ${size.width}x${size.height}',
      (tester) async {
        final members = <String>[];
        var settleTaps = 0;

        await show(
          tester,
          size: size,
          summary: BalanceSummary(
            youAreOwed: 6000,
            youOwe: 4000,
            net: 2000,
            byMember: {'jean': 6000, 'grace': -4000},
          ),
          onSettleUp: () => settleTaps++,
          onMemberTap: members.add,
        );

        expect(find.text('RWF 6,000'), findsNWidgets(2));
        expect(find.text('RWF 4,000'), findsNWidgets(2));
        expect(find.text('All settled up'), findsNothing);
        expect(tester.takeException(), isNull);

        await tapVisible(tester, find.byKey(const Key('balance-settle-up')));

        for (final uid in ['jean', 'grace']) {
          await tapVisible(tester, find.byKey(Key('balance-row-$uid')));
          expect(tester.takeException(), isNull);
        }

        expect(settleTaps, 1);
        expect(members, ['jean', 'grace']);
      },
    );
  }
}
