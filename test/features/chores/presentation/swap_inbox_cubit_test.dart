import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:changa_app/core/error/failures.dart';
import 'package:changa_app/core/error/result.dart';
import 'package:changa_app/features/chores/domain/entities/chore.dart';
import 'package:changa_app/features/chores/domain/entities/swap_request.dart';
import 'package:changa_app/features/chores/domain/usecases/respond_to_swap.dart';
import 'package:changa_app/features/chores/domain/usecases/watch_all_chores.dart';
import 'package:changa_app/features/chores/domain/usecases/watch_swap_requests.dart';
import 'package:changa_app/features/chores/presentation/cubit/swap_inbox_cubit.dart';

class MockWatchSwapRequests extends Mock implements WatchSwapRequests {}

class MockWatchAllChores extends Mock implements WatchAllChores {}

class MockRespondToSwap extends Mock implements RespondToSwap {}

SwapRequest _request(String id, {String choreId = 'c1'}) => SwapRequest(
  id: id,
  choreId: choreId,
  fromUid: 'kevin',
  toUid: 'me',
  status: SwapStatus.pending,
  createdAt: DateTime(2026, 11, 10),
);

Chore _chore(String id, String title) => Chore(
  id: id,
  title: title,
  difficulty: ChoreDifficulty.easy,
  assignedToUid: 'kevin',
  dueDate: DateTime(2026, 11, 12),
  status: ChoreStatus.pending,
  createdByUid: 'kevin',
  createdAt: DateTime(2026, 11, 1),
);

void main() {
  late MockWatchSwapRequests watchRequests;
  late MockWatchAllChores watchChores;
  late MockRespondToSwap respond;
  late StreamController<List<SwapRequest>> requests;
  late StreamController<List<Chore>> chores;
  late SwapInboxCubit cubit;

  Future<void> pump() => Future<void>.delayed(Duration.zero);

  setUp(() {
    watchRequests = MockWatchSwapRequests();
    watchChores = MockWatchAllChores();
    respond = MockRespondToSwap();
    requests = StreamController<List<SwapRequest>>();
    chores = StreamController<List<Chore>>();
    when(() => watchRequests('home', 'me')).thenAnswer((_) => requests.stream);
    when(() => watchChores('home')).thenAnswer((_) => chores.stream);

    cubit = SwapInboxCubit(
      watchSwapRequests: watchRequests,
      watchAllChores: watchChores,
      respondToSwap: respond,
      householdId: 'home',
      meUid: 'me',
    )..start();
  });

  tearDown(() async {
    await cubit.close();
    await requests.close();
    await chores.close();
  });

  test('keeps the open requests and the chore names', () async {
    requests.add([_request('r1')]);
    chores.add([_chore('c1', 'Dishes')]);
    await pump();

    expect(cubit.state.requests.map((r) => r.id), ['r1']);
    expect(cubit.state.titleFor(cubit.state.requests.first), 'Dishes');
  });

  test('uses a plain fallback when the chore is unknown', () async {
    requests.add([_request('r1', choreId: 'gone')]);
    await pump();

    expect(cubit.state.titleFor(cubit.state.requests.first), 'a chore');
  });

  test('accepting tells the user the chore is theirs', () async {
    when(() => respond(householdId: 'home', requestId: 'r1', accept: true))
        .thenAnswer((_) async => Result<void>.success(null));
    requests.add([_request('r1')]);
    await pump();

    await cubit.respond('r1', accept: true);

    expect(cubit.state.notice?.isError, isFalse);
    expect(cubit.state.notice?.text, contains('now yours'));
    expect(cubit.state.respondingIds, isEmpty);
  });

  test('declining says so', () async {
    when(() => respond(householdId: 'home', requestId: 'r1', accept: false))
        .thenAnswer((_) async => Result<void>.success(null));
    requests.add([_request('r1')]);
    await pump();

    await cubit.respond('r1', accept: false);

    expect(cubit.state.notice?.text, 'Swap declined.');
  });

  test('shows the reason when answering fails', () async {
    when(() => respond(householdId: 'home', requestId: 'r1', accept: true))
        .thenAnswer(
          (_) async => Result<void>.failure(
            const ValidationFailure('This chore was already done.'),
          ),
        );
    requests.add([_request('r1')]);
    await pump();

    await cubit.respond('r1', accept: true);

    expect(cubit.state.notice?.isError, isTrue);
    expect(cubit.state.notice?.text, 'This chore was already done.');
  });

  test('unknown requests and double taps are ignored', () async {
    final answering = Completer<Result<void>>();
    when(() => respond(householdId: 'home', requestId: 'r1', accept: true))
        .thenAnswer((_) => answering.future);
    requests.add([_request('r1')]);
    await pump();

    await cubit.respond('missing', accept: true);
    final first = cubit.respond('r1', accept: true);
    await pump();
    expect(cubit.state.respondingIds, {'r1'});
    await cubit.respond('r1', accept: true);
    answering.complete(Result<void>.success(null));
    await first;

    verify(() => respond(householdId: 'home', requestId: 'r1', accept: true))
        .called(1);
  });

  test('the notice can be cleared', () async {
    when(
      () => respond(
        householdId: any(named: 'householdId'),
        requestId: any(named: 'requestId'),
        accept: any(named: 'accept'),
      ),
    ).thenAnswer((_) async => Result<void>.success(null));
    requests.add([_request('r1')]);
    await pump();
    await cubit.respond('r1', accept: false);

    cubit.clearNotice();

    expect(cubit.state.notice, isNull);
  });
}
