import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:changa_app/core/theme/app_theme.dart';
import 'package:changa_app/features/chores/domain/entities/chore.dart';
import 'package:changa_app/features/chores/presentation/widgets/difficulty_selector.dart';

Widget _wrap({
  ChoreDifficulty selected = ChoreDifficulty.medium,
  ValueChanged<ChoreDifficulty>? onChanged,
  bool enabled = true,
}) => MaterialApp(
  theme: AppTheme.lightTheme,
  home: Scaffold(
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: DifficultySelector(
        selected: selected,
        enabled: enabled,
        onChanged: onChanged ?? (_) {},
      ),
    ),
  ),
);

void main() {
  testWidgets('shows each level with its points', (tester) async {
    await tester.pumpWidget(_wrap());

    for (final difficulty in ChoreDifficulty.values) {
      expect(find.text(difficulty.label), findsOneWidget);
      expect(find.text('${difficulty.credits} pts'), findsOneWidget);
    }
  });

  testWidgets('tapping a level reports it', (tester) async {
    ChoreDifficulty? picked;
    await tester.pumpWidget(_wrap(onChanged: (d) => picked = d));

    await tester.tap(find.text('Hard'));

    expect(picked, ChoreDifficulty.hard);
  });

  testWidgets('does nothing while disabled', (tester) async {
    ChoreDifficulty? picked;
    await tester.pumpWidget(
      _wrap(enabled: false, onChanged: (d) => picked = d),
    );

    await tester.tap(find.text('Easy'));

    expect(picked, isNull);
  });
}
