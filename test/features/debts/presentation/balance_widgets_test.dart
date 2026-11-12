import 'package:changa_app/core/theme/app_theme.dart';
import 'package:changa_app/features/debts/domain/entities/balance_summary.dart';
import 'package:changa_app/features/debts/presentation/widgets/balance_card.dart';
import 'package:changa_app/features/debts/presentation/widgets/housemate_balance_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Widget child, {double textScale = 1}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      builder: (context, content) {
        return MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: content!,
        );
      },
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Align(alignment: Alignment.topLeft, child: child),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('balance card shows both totals and positive net', (
    tester,
  ) async {
    await _pump(
      tester,
      BalanceCard(
        summary: BalanceSummary(
          youAreOwed: 18500,
          youOwe: 6200,
          net: 12300,
          byMember: {'kevin': 18500, 'grace': -6200},
        ),
      ),
    );

    expect(find.text('You are owed'), findsOneWidget);
    expect(find.text('RWF 18,500'), findsOneWidget);
    expect(find.text('You owe'), findsOneWidget);
    expect(find.text('RWF 6,200'), findsOneWidget);
    expect(find.text('Net balance: +RWF 12,300'), findsOneWidget);
  });

  testWidgets('balance card formats a negative net', (tester) async {
    await _pump(
      tester,
      BalanceCard(
        summary: BalanceSummary(
          youAreOwed: 1000,
          youOwe: 3000,
          net: -2000,
          byMember: {'kevin': 1000, 'grace': -3000},
        ),
      ),
    );

    expect(find.text('Net balance: -RWF 2,000'), findsOneWidget);
  });

  testWidgets('settlement button calls its callback', (tester) async {
    var taps = 0;

    await _pump(
      tester,
      BalanceCard(
        summary: BalanceSummary(
          youAreOwed: 6000,
          youOwe: 0,
          net: 6000,
          byMember: {'kevin': 6000},
        ),
        onSettleUp: () => taps++,
      ),
    );

    await tester.tap(find.text('Settle Up'));

    expect(taps, 1);
  });

  testWidgets('zero balances show the settled state', (tester) async {
    await _pump(
      tester,
      BalanceCard(
        summary: BalanceSummary(youAreOwed: 0, youOwe: 0, net: 0, byMember: {}),
        onSettleUp: () {},
      ),
    );

    expect(find.text('All settled up'), findsOneWidget);
    expect(find.text('You owe RWF 0 · You’re owed RWF 0'), findsOneWidget);
    expect(find.text('Settle Up'), findsNothing);
  });

  testWidgets('zero net with different creditors is not all settled', (
    tester,
  ) async {
    await _pump(
      tester,
      BalanceCard(
        summary: BalanceSummary(
          youAreOwed: 1000,
          youOwe: 1000,
          net: 0,
          byMember: {'kevin': 1000, 'grace': -1000},
        ),
      ),
    );

    expect(find.text('All settled up'), findsNothing);
    expect(find.text('Net balance: RWF 0'), findsOneWidget);
  });

  testWidgets('chip describes positive, negative, and zero balances', (
    tester,
  ) async {
    for (final entry in {
      6000: 'Owes you RWF 6,000',
      -4000: 'You owe RWF 4,000',
      0: 'All settled up',
    }.entries) {
      await _pump(
        tester,
        HousemateBalanceChip(displayName: 'Kevin', balance: entry.key),
      );

      expect(find.text('Kevin'), findsOneWidget);
      expect(find.text(entry.value), findsOneWidget);
    }
  });

  testWidgets('chip uses Former member for a blank name', (tester) async {
    await _pump(
      tester,
      const HousemateBalanceChip(displayName: '   ', balance: 6000),
    );

    expect(find.text('Former member'), findsOneWidget);
    expect(find.text('Owes you RWF 6,000'), findsOneWidget);
  });

  testWidgets('tapping a chip calls its navigation callback', (tester) async {
    var taps = 0;

    await _pump(
      tester,
      HousemateBalanceChip(
        displayName: 'Kevin',
        balance: 6000,
        onTap: () => taps++,
      ),
    );

    await tester.tap(find.text('Kevin'));

    expect(taps, 1);
  });

  testWidgets('widgets fit a narrow screen with larger text', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pump(
      tester,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BalanceCard(
            summary: BalanceSummary(
              youAreOwed: 18500,
              youOwe: 6200,
              net: 12300,
              byMember: {'kevin': 18500, 'grace': -6200},
            ),
            onSettleUp: () {},
          ),
          const SizedBox(height: 16),
          HousemateBalanceChip(
            displayName: 'Kevin with a very long household display name',
            balance: -4000,
            onTap: () {},
          ),
        ],
      ),
      textScale: 2,
    );

    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text('Settle Up'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
