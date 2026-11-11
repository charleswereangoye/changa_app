import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:changa_app/core/error/failures.dart';
import 'package:changa_app/core/error/result.dart';
import 'package:changa_app/features/chores/domain/entities/chore.dart';
import 'package:changa_app/features/chores/domain/usecases/complete_chore.dart';
import 'package:changa_app/features/chores/domain/usecases/watch_chores_for_day.dart';
import 'package:changa_app/features/chores/presentation/cubit/chores_cubit.dart';

class MockWatchChoresForDay extends Mock implements WatchChoresForDay {}

class MockCompleteChore extends Mock implements CompleteChore {}

Chore _chore(
  String id,
  String title, {
  String assignee = 'me',
  ChoreDifficulty difficulty = ChoreDifficulty.medium,
  ChoreStatus status = ChoreStatus.pending,
}) {
  return Chore(
    id: id,
    title: title,
    difficulty: difficulty,
    assignedToUid: assignee,
    dueDate: DateTime(2026, 11, 11),
    status: status,
    createdByUid: 'me',
    createdAt: DateTime(2026, 11, 1),
  );
}

void main() {
  late MockWatchChoresForDay watchChores;
  late MockCompleteChore completeChore;
  late List<StreamController<List<Chore>>> streams;
  late ChoresCubit cubit;

  Future<void> pump() => Future<void>.delayed(Duration.zero);

  setUpAll(() => registerFallbackValue(DateTime(2026)));

  setUp(() {
    watchChores = MockWatchChoresForDay();
    completeChore = MockCompleteChore();
    streams = [];

    when(() => watchChores(any(), any())).thenAnswer((_) {
      final controller = StreamController<List<Chore>>();
      streams.add(controller);
      return controller.stream;
    });

    cubit = ChoresCubit(
      watchChoresForDay: watchChores,
      completeChore: completeChore,
      householdId: 'home',
      meUid: 'me',
      clock: () => DateTime(2026, 11, 11, 9),
    );
  });

  tearDown(() async {
    await cubit.close();
    for (final stream in streams) {
      await stream.close();
    }
  });

  group('loading', () {
    test('starts on today, in the loading state', () {
      expect(cubit.state.status, ChoresStatus.loading);
      expect(cubit.state.selectedDay, DateTime(2026, 11, 11));
      expect(cubit.state.isSelectedDayToday, isTrue);
    });

    test('the week runs Monday to Sunday', () {
      expect(cubit.state.weekDays.first, DateTime(2026, 11, 9));
      expect(cubit.state.weekDays.last, DateTime(2026, 11, 15));
    });

    test('open chores come first, then finished ones', () async {
      cubit.load();
      streams.last.add([
        _chore('c3', 'Bins', status: ChoreStatus.done),
        _chore('c2', 'Sweep'),
        _chore('c1', 'Dishes'),
      ]);
      await pump();

      expect(cubit.state.status, ChoresStatus.loaded);
      expect(cubit.state.chores.map((c) => c.title), [
        'Dishes',
        'Sweep',
        'Bins',
      ]);
    });

    test('a stream error becomes a friendly failure', () async {
      cubit.load();
      streams.last.addError(Exception('boom'));
      await pump();

      expect(cubit.state.status, ChoresStatus.failure);
      expect(cubit.state.failure?.message, contains('couldn’t load'));
    });

    test('retry starts watching again', () async {
      cubit.load();
      streams.last.addError(Exception('boom'));
      await pump();

      cubit.retry();
      streams.last.add([_chore('c1', 'Dishes')]);
      await pump();

      expect(cubit.state.status, ChoresStatus.loaded);
      expect(streams, hasLength(2));
    });
  });

  group('choosing a day', () {
    test('watches the new day and clears the old list', () async {
      cubit.load();
      streams.last.add([_chore('c1', 'Dishes')]);
      await pump();

      cubit.selectDay(DateTime(2026, 11, 13, 18));

      expect(cubit.state.selectedDay, DateTime(2026, 11, 13));
      expect(cubit.state.status, ChoresStatus.loading);
      expect(cubit.state.chores, isEmpty);
      verify(() => watchChores('home', DateTime(2026, 11, 13))).called(1);
    });

    test('picking the open day again does nothing', () async {
      cubit.load();
      cubit.selectDay(DateTime(2026, 11, 11));

      expect(streams, hasLength(1));
    });

    test('late data from the previous day is ignored', () async {
      cubit.load();
      final first = streams.last;
      cubit.selectDay(DateTime(2026, 11, 12));

      first.add([_chore('old', 'Old chore')]);
      await pump();

      expect(cubit.state.chores, isEmpty);
    });
  });

  group('completing a chore', () {
    Future<void> loadOne(Chore chore) async {
      cubit.load();
      streams.last.add([chore]);
      await pump();
    }

    test('tells you the points you earned', () async {
      final chore = _chore('c1', 'Dishes');
      when(() => completeChore('home', 'c1'))
          .thenAnswer((_) async => Result<void>.success(null));
      await loadOne(chore);

      await cubit.completeChore('c1');

      verify(() => completeChore('home', 'c1')).called(1);
      expect(cubit.state.completingIds, isEmpty);
      expect(cubit.state.notice?.isError, isFalse);
      expect(
        cubit.state.notice?.text,
        'Nice work! +${chore.difficulty.credits} pts',
      );
    });

    test('shows the reason when it fails', () async {
      when(() => completeChore('home', 'c1')).thenAnswer(
        (_) async => Result<void>.failure(const ValidationFailure('Too late.')),
      );
      await loadOne(_chore('c1', 'Dishes'));

      await cubit.completeChore('c1');

      expect(cubit.state.notice?.isError, isTrue);
      expect(cubit.state.notice?.text, 'Too late.');
    });

    test('you cannot complete a housemate’s chore', () async {
      await loadOne(_chore('c1', 'Dishes', assignee: 'kevin'));

      await cubit.completeChore('c1');

      verifyNever(() => completeChore(any(), any()));
    });

    test('a finished chore cannot be completed again', () async {
      await loadOne(_chore('c1', 'Dishes', status: ChoreStatus.done));

      await cubit.completeChore('c1');

      verifyNever(() => completeChore(any(), any()));
    });

    test('a second tap while saving is ignored', () async {
      final saving = Completer<Result<void>>();
      when(() => completeChore('home', 'c1')).thenAnswer((_) => saving.future);
      await loadOne(_chore('c1', 'Dishes'));

      final first = cubit.completeChore('c1');
      await pump();
      expect(cubit.state.completingIds, {'c1'});

      await cubit.completeChore('c1');
      saving.complete(Result<void>.success(null));
      await first;

      verify(() => completeChore('home', 'c1')).called(1);
    });

    test('the same message twice still counts as new', () async {
      when(() => completeChore('home', any()))
          .thenAnswer((_) async => Result<void>.success(null));
      cubit.load();
      streams.last.add([_chore('c1', 'Dishes'), _chore('c2', 'Sweep')]);
      await pump();

      await cubit.completeChore('c1');
      final first = cubit.state.notice;
      await cubit.completeChore('c2');

      expect(cubit.state.notice, isNot(first));
    });

    test('the message can be cleared once shown', () async {
      when(() => completeChore('home', 'c1'))
          .thenAnswer((_) async => Result<void>.success(null));
      await loadOne(_chore('c1', 'Dishes'));
      await cubit.completeChore('c1');

      cubit.clearNotice();

      expect(cubit.state.notice, isNull);
    });
  });

  test('closing stops listening to the chores', () async {
    cubit.load();
    final stream = streams.last;
    expect(stream.hasListener, isTrue);

    await cubit.close();

    expect(stream.hasListener, isFalse);
  });
}
