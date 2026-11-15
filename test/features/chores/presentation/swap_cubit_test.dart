import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:changa_app/core/error/failures.dart';
import 'package:changa_app/core/error/result.dart';
import 'package:changa_app/features/chores/domain/entities/chore.dart';
import 'package:changa_app/features/chores/domain/usecases/request_swap.dart';
import 'package:changa_app/features/chores/domain/usecases/watch_all_chores.dart';
import 'package:changa_app/features/chores/presentation/cubit/swap_cubit.dart';

class MockRequestSwap extends Mock implements RequestSwap {}

class MockWatchAllChores extends Mock implements WatchAllChores {}

Chore _chore(String id, String assignee, DateTime due, {bool done = false}) {
  return Chore(
    id: id,
    title: 'Chore $id',
    difficulty: ChoreDifficulty.easy,
    assignedToUid: assignee,
    dueDate: due,
    status: done ? ChoreStatus.done : ChoreStatus.pending,
    createdByUid: 'me',
    createdAt: DateTime(2026, 11, 1),
  );
}

void main() {
  late MockRequestSwap requestSwap;
  late MockWatchAllChores watchAll;
  late StreamController<List<Chore>> chores;
  late SwapCubit cubit;

  const kevin = SwapCandidate(uid: 'kevin', name: 'Kevin Mugo');
  const jean = SwapCandidate(uid: 'jean', name: 'Jean Baptiste');

  Future<void> pump() => Future<void>.delayed(Duration.zero);

  setUp(() {
    requestSwap = MockRequestSwap();
    watchAll = MockWatchAllChores();
    chores = StreamController<List<Chore>>();
    when(() => watchAll(any())).thenAnswer((_) => chores.stream);

    cubit = SwapCubit(
      requestSwap: requestSwap,
      watchAllChores: watchAll,
      householdId: 'home',
      chore: _chore('c1', 'me', DateTime(2026, 11, 12)),
      candidates: const [kevin, jean],
      clock: () => DateTime(2026, 11, 11, 9),
    );
  });

  tearDown(() async {
    await cubit.close();
    await chores.close();
  });

  test('counts this week’s open chores for each housemate', () async {
    cubit.load();
    chores.add([
      _chore('a', 'kevin', DateTime(2026, 11, 9)),
      _chore('b', 'kevin', DateTime(2026, 11, 15, 20)),
      _chore('c', 'kevin', DateTime(2026, 11, 16)),
      _chore('d', 'kevin', DateTime(2026, 11, 10), done: true),
      _chore('e', 'jean', DateTime(2026, 11, 12)),
    ]);
    await pump();

    expect(cubit.state.countFor('kevin'), 2);
    expect(cubit.state.countFor('jean'), 1);
    expect(cubit.state.countFor('nobody'), 0);
  });

  test('a failing stream leaves the sheet usable', () async {
    cubit.load();
    chores.addError(Exception('offline'));
    await pump();

    expect(cubit.state.weekCounts, isEmpty);
    expect(cubit.state.status, SwapFormStatus.idle);
  });

  test('sends the request with the trimmed note', () async {
    when(
      () => requestSwap(
        householdId: any(named: 'householdId'),
        choreId: any(named: 'choreId'),
        toUid: any(named: 'toUid'),
        note: any(named: 'note'),
      ),
    ).thenAnswer((_) async => Result<void>.success(null));
    cubit.noteChanged('  Exam week  ');

    await cubit.request('kevin');

    verify(
      () => requestSwap(
        householdId: 'home',
        choreId: 'c1',
        toUid: 'kevin',
        note: 'Exam week',
      ),
    ).called(1);
    expect(cubit.state.status, SwapFormStatus.sent);
    expect(cubit.state.message, 'Swap request sent to Kevin Mugo.');
  });

  test('a blank note is sent as no note', () async {
    when(
      () => requestSwap(
        householdId: any(named: 'householdId'),
        choreId: any(named: 'choreId'),
        toUid: any(named: 'toUid'),
        note: any(named: 'note'),
      ),
    ).thenAnswer((_) async => Result<void>.success(null));
    cubit.noteChanged('   ');

    await cubit.request('jean');

    verify(
      () => requestSwap(
        householdId: 'home',
        choreId: 'c1',
        toUid: 'jean',
        note: null,
      ),
    ).called(1);
  });

  test('shows the reason when the request fails', () async {
    when(
      () => requestSwap(
        householdId: any(named: 'householdId'),
        choreId: any(named: 'choreId'),
        toUid: any(named: 'toUid'),
        note: any(named: 'note'),
      ),
    ).thenAnswer(
      (_) async => Result<void>.failure(
        const ValidationFailure('A swap is already waiting.'),
      ),
    );

    await cubit.request('kevin');

    expect(cubit.state.status, SwapFormStatus.failure);
    expect(cubit.state.message, 'A swap is already waiting.');
    expect(cubit.state.sendingUid, isNull);
  });

  test('ignores people who are not in the list', () async {
    await cubit.request('stranger');

    verifyNever(
      () => requestSwap(
        householdId: any(named: 'householdId'),
        choreId: any(named: 'choreId'),
        toUid: any(named: 'toUid'),
        note: any(named: 'note'),
      ),
    );
  });

  test('a second tap while sending is ignored', () async {
    final sending = Completer<Result<void>>();
    when(
      () => requestSwap(
        householdId: any(named: 'householdId'),
        choreId: any(named: 'choreId'),
        toUid: any(named: 'toUid'),
        note: any(named: 'note'),
      ),
    ).thenAnswer((_) => sending.future);

    final first = cubit.request('kevin');
    await pump();
    expect(cubit.state.sendingUid, 'kevin');
    await cubit.request('jean');
    sending.complete(Result<void>.success(null));
    await first;

    verify(
      () => requestSwap(
        householdId: any(named: 'householdId'),
        choreId: any(named: 'choreId'),
        toUid: any(named: 'toUid'),
        note: any(named: 'note'),
      ),
    ).called(1);
  });
}
