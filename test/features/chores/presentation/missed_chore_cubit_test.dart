import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:changa_app/core/error/failures.dart';
import 'package:changa_app/core/error/result.dart';
import 'package:changa_app/features/chores/domain/entities/chore.dart';
import 'package:changa_app/features/chores/domain/usecases/complete_chore.dart';
import 'package:changa_app/features/chores/domain/usecases/watch_all_chores.dart';
import 'package:changa_app/features/chores/presentation/cubit/missed_chore_cubit.dart';

class MockWatchAllChores extends Mock implements WatchAllChores {}

class MockCompleteChore extends Mock implements CompleteChore {}

Chore _chore(
  String id, {
  String assignee = 'me',
  DateTime? due,
  bool done = false,
  ChoreDifficulty difficulty = ChoreDifficulty.hard,
}) {
  return Chore(
    id: id,
    title: 'Chore $id',
    difficulty: difficulty,
    assignedToUid: assignee,
    dueDate: due ?? DateTime(2026, 11, 8),
    status: done ? ChoreStatus.done : ChoreStatus.pending,
    createdByUid: 'me',
    createdAt: DateTime(2026, 11, 1),
  );
}

void main() {
  late MockWatchAllChores watchAll;
  late MockCompleteChore complete;
  late StreamController<List<Chore>> stream;
  late MissedChoreCubit cubit;

  Future<void> pump() => Future<void>.delayed(Duration.zero);

  setUp(() {
    watchAll = MockWatchAllChores();
    complete = MockCompleteChore();
    stream = StreamController<List<Chore>>();
    when(() => watchAll('home')).thenAnswer((_) => stream.stream);

    cubit = MissedChoreCubit(
      watchAllChores: watchAll,
      completeChore: complete,
      householdId: 'home',
      meUid: 'me',
      clock: () => DateTime(2026, 11, 11, 9),
    )..start();
  });

  tearDown(() async {
    await cubit.close();
    await stream.close();
  });

  test('asks about the oldest missed chore of mine', () async {
    stream.add([
      _chore('new', due: DateTime(2026, 11, 10)),
      _chore('old', due: DateTime(2026, 11, 5)),
    ]);
    await pump();

    expect(cubit.state.prompt?.id, 'old');
    expect(cubit.state.otherCount, 1);
  });

  test('ignores other people’s, done and future chores', () async {
    stream.add([
      _chore('theirs', assignee: 'kevin'),
      _chore('finished', done: true),
      _chore('today', due: DateTime(2026, 11, 11)),
      _chore('later', due: DateTime(2026, 11, 14)),
    ]);
    await pump();

    expect(cubit.state.prompt, isNull);
  });

  test('only asks once per session', () async {
    stream.add([_chore('a')]);
    await pump();
    cubit.dismiss();

    stream.add([_chore('a'), _chore('b')]);
    await pump();

    expect(cubit.state.prompt, isNull);
  });

  test('dismissing clears the question', () async {
    stream.add([_chore('a')]);
    await pump();

    cubit.dismiss();

    expect(cubit.state.prompt, isNull);
    verifyNever(() => complete(any(), any()));
  });

  test('marking it done reports the points', () async {
    when(() => complete('home', 'a'))
        .thenAnswer((_) async => Result<void>.success(null));
    stream.add([_chore('a', difficulty: ChoreDifficulty.medium)]);
    await pump();

    await cubit.completePrompt();

    expect(cubit.state.prompt, isNull);
    expect(cubit.state.notice?.isError, isFalse);
    expect(
      cubit.state.notice?.text,
      'Nice work! +${ChoreDifficulty.medium.credits} pts',
    );
  });

  test('shows the reason when finishing fails', () async {
    when(() => complete('home', 'a')).thenAnswer(
      (_) async =>
          Result<void>.failure(const ValidationFailure('Already done.')),
    );
    stream.add([_chore('a')]);
    await pump();

    await cubit.completePrompt();

    expect(cubit.state.notice?.isError, isTrue);
    expect(cubit.state.notice?.text, 'Already done.');
  });

  test('does nothing when there is no question', () async {
    await cubit.completePrompt();

    verifyNever(() => complete(any(), any()));
  });
}
