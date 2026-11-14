import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:changa_app/core/error/result.dart';
import 'package:changa_app/core/theme/app_theme.dart';
import 'package:changa_app/features/chores/domain/entities/chore.dart';
import 'package:changa_app/features/chores/domain/usecases/complete_chore.dart';
import 'package:changa_app/features/chores/domain/usecases/watch_all_chores.dart';
import 'package:changa_app/features/chores/presentation/cubit/missed_chore_cubit.dart';
import 'package:changa_app/features/chores/presentation/widgets/missed_chore_modal.dart';

class MockWatchAllChores extends Mock implements WatchAllChores {}

class MockCompleteChore extends Mock implements CompleteChore {}

final _chore = Chore(
  id: 'c1',
  title: 'Wash dishes',
  difficulty: ChoreDifficulty.medium,
  assignedToUid: 'me',
  dueDate: DateTime(2026, 11, 9),
  status: ChoreStatus.pending,
  createdByUid: 'me',
  createdAt: DateTime(2026, 11, 1),
);

void main() {
  late MockCompleteChore complete;
  late MissedChoreCubit cubit;

  setUp(() {
    complete = MockCompleteChore();
    final watchAll = MockWatchAllChores();
    when(() => watchAll(any())).thenAnswer((_) => Stream.value([_chore]));
    cubit = MissedChoreCubit(
      watchAllChores: watchAll,
      completeChore: complete,
      householdId: 'home',
      meUid: 'me',
      clock: () => DateTime(2026, 11, 11, 9),
    )..start();
  });

  tearDown(() => cubit.close());

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => MissedChoreModal.show(context, cubit),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('names the chore, its day and the points', (tester) async {
    await open(tester);

    expect(find.text('You missed a chore'), findsOneWidget);
    expect(find.textContaining('Wash dishes was due Mon 9'), findsOneWidget);
    expect(
      find.textContaining('${ChoreDifficulty.medium.credits} pts'),
      findsOneWidget,
    );
  });

  testWidgets('Mark Done completes the chore and closes', (tester) async {
    when(() => complete('home', 'c1'))
        .thenAnswer((_) async => Result<void>.success(null));
    await open(tester);

    await tester.tap(find.text('Mark Done'));
    await tester.pumpAndSettle();

    verify(() => complete('home', 'c1')).called(1);
    expect(find.text('You missed a chore'), findsNothing);
  });

  testWidgets('Dismiss closes without completing', (tester) async {
    await open(tester);

    await tester.tap(find.text('Dismiss'));
    await tester.pumpAndSettle();

    verifyNever(() => complete(any(), any()));
    expect(find.text('You missed a chore'), findsNothing);
    expect(cubit.state.prompt, isNull);
  });
}
