import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:changa_app/core/theme/app_theme.dart';
import 'package:changa_app/features/chores/domain/entities/chore.dart';
import 'package:changa_app/features/chores/presentation/widgets/chore_card.dart';

final _now = DateTime(2026, 11, 11, 9);

Chore _chore({
  ChoreStatus status = ChoreStatus.pending,
  DateTime? due,
  int? creditsAwarded,
}) {
  return Chore(
    id: 'c1',
    title: 'Sweep living room',
    difficulty: ChoreDifficulty.easy,
    assignedToUid: 'me',
    dueDate: due ?? DateTime(2026, 11, 11),
    status: status,
    creditsAwarded: creditsAwarded,
    createdByUid: 'me',
    createdAt: DateTime(2026, 11, 1),
  );
}

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.lightTheme,
  home: Scaffold(
    body: Padding(padding: const EdgeInsets.all(16), child: child),
  ),
);

void main() {
  testWidgets('shows the title, due day and points', (tester) async {
    await tester.pumpWidget(
      _wrap(
        ChoreCard(
          chore: _chore(),
          assigneeName: 'You',
          isMine: true,
          now: _now,
        ),
      ),
    );

    expect(find.text('Sweep living room'), findsOneWidget);
    expect(find.text('You · Due today'), findsOneWidget);
    expect(find.text('+${ChoreDifficulty.easy.credits} pts'), findsOneWidget);
  });

  testWidgets('your own open chore can be completed and edited', (
    tester,
  ) async {
    var completed = 0;
    var edited = 0;
    await tester.pumpWidget(
      _wrap(
        ChoreCard(
          chore: _chore(),
          assigneeName: 'You',
          isMine: true,
          now: _now,
          onComplete: () => completed++,
          onEdit: () => edited++,
        ),
      ),
    );

    await tester.tap(find.text('Mark Done'));
    await tester.tap(find.byTooltip('Edit chore'));

    expect(completed, 1);
    expect(edited, 1);
    expect(find.byTooltip('Swap this chore'), findsNothing);
  });

  testWidgets('the swap button only shows when swapping is wired up', (
    tester,
  ) async {
    var swapped = 0;
    await tester.pumpWidget(
      _wrap(
        ChoreCard(
          chore: _chore(),
          assigneeName: 'You',
          isMine: true,
          now: _now,
          onSwap: () => swapped++,
        ),
      ),
    );

    await tester.tap(find.byTooltip('Swap this chore'));

    expect(swapped, 1);
  });

  testWidgets('a housemate’s chore has no buttons', (tester) async {
    await tester.pumpWidget(
      _wrap(
        ChoreCard(
          chore: _chore(),
          assigneeName: 'Jean',
          isMine: false,
          now: _now,
          onComplete: () {},
          onEdit: () {},
        ),
      ),
    );

    expect(find.text('Jean · Due today'), findsOneWidget);
    expect(find.text('Mark Done'), findsNothing);
    expect(find.byTooltip('Edit chore'), findsNothing);
  });

  testWidgets('a finished chore shows Done with the points it earned', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        ChoreCard(
          chore: _chore(status: ChoreStatus.done, creditsAwarded: 30),
          assigneeName: 'You',
          isMine: true,
          now: _now,
        ),
      ),
    );

    expect(find.text('You · Done'), findsOneWidget);
    expect(find.text('+30 pts'), findsOneWidget);
    expect(find.text('Mark Done'), findsNothing);
  });

  testWidgets('a chore past its day is marked missed', (tester) async {
    await tester.pumpWidget(
      _wrap(
        ChoreCard(
          chore: _chore(due: DateTime(2026, 11, 8)),
          assigneeName: 'You',
          isMine: true,
          isMissed: true,
          now: _now,
        ),
      ),
    );

    expect(find.text('You · Missed'), findsOneWidget);
  });

  testWidgets('due labels read naturally', (tester) async {
    Future<void> expectLabel(DateTime due, String label) async {
      await tester.pumpWidget(
        _wrap(
          ChoreCard(
            chore: _chore(due: due),
            assigneeName: 'Jean',
            isMine: false,
            now: _now,
          ),
        ),
      );
      expect(find.text('Jean · $label'), findsOneWidget);
    }

    await expectLabel(DateTime(2026, 11, 12), 'Due tomorrow');
    await expectLabel(DateTime(2026, 11, 10), 'Due yesterday');
    await expectLabel(DateTime(2026, 11, 14), 'Due Sat 14');
  });

  testWidgets('saving disables the buttons', (tester) async {
    await tester.pumpWidget(
      _wrap(
        ChoreCard(
          chore: _chore(),
          assigneeName: 'You',
          isMine: true,
          isCompleting: true,
          now: _now,
          onComplete: () {},
          onEdit: () {},
        ),
      ),
    );

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
