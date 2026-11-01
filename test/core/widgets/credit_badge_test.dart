import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:changa_app/core/theme/app_colors.dart';
import 'package:changa_app/core/theme/app_theme.dart';
import 'package:changa_app/core/widgets/credit_badge.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  testWidgets('shows a reward with a plus sign', (tester) async {
    await tester.pumpWidget(_wrap(const CreditBadge(credits: 20)));
    expect(find.text('+20 pts'), findsOneWidget);
  });

  testWidgets('shows a balance without a plus sign', (tester) async {
    await tester.pumpWidget(
      _wrap(const CreditBadge(credits: 340, showPlus: false)),
    );
    expect(find.text('340 pts'), findsOneWidget);
  });

  testWidgets('uses the badge colours from the theme', (tester) async {
    await tester.pumpWidget(_wrap(const CreditBadge(credits: 10)));

    final box = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byType(CreditBadge),
        matching: find.byType(DecoratedBox),
      ),
    );
    expect((box.decoration as BoxDecoration).color, AppColors.athsSpecial);

    final text = tester.widget<Text>(find.text('+10 pts'));
    expect(text.style?.color, AppColors.sherwoodGreen);
  });

  testWidgets('is announced as credits for screen readers', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_wrap(const CreditBadge(credits: 20)));
    expect(find.bySemanticsLabel('20 credits'), findsOneWidget);
    handle.dispose();
  });
}
