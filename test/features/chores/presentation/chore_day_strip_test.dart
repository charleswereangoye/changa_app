import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:changa_app/core/theme/app_theme.dart';
import 'package:changa_app/core/utils/date_helpers.dart';
import 'package:changa_app/features/chores/presentation/widgets/chore_day_strip.dart';

void main() {
  final today = DateTime(2026, 11, 11);
  final days = DateHelpers.weekDays(today);

  Widget strip(ValueChanged<DateTime> onSelected) => MaterialApp(
    theme: AppTheme.lightTheme,
    home: Scaffold(
      body: ChoreDayStrip(
        days: days,
        selected: today,
        today: today,
        onSelected: onSelected,
      ),
    ),
  );

  testWidgets('shows all seven days of the week', (tester) async {
    await tester.pumpWidget(strip((_) {}));

    for (final label in ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('9'), findsOneWidget);
    expect(find.text('15'), findsOneWidget);
  });

  testWidgets('tapping a day reports that date', (tester) async {
    DateTime? picked;
    await tester.pumpWidget(strip((day) => picked = day));

    await tester.tap(find.text('13'));

    expect(picked, DateTime(2026, 11, 13));
  });

  testWidgets('every day is reachable by screen readers', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(strip((_) {}));

    expect(find.bySemanticsLabel('Wed 11'), findsOneWidget);
    expect(find.bySemanticsLabel('Sun 15'), findsOneWidget);
    handle.dispose();
  });
}
