import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:changa_app/core/error/failures.dart';
import 'package:changa_app/core/error/result.dart';
import 'package:changa_app/features/chores/domain/entities/chore.dart';
import 'package:changa_app/features/chores/domain/entities/new_chore_input.dart';
import 'package:changa_app/features/chores/domain/usecases/create_chore.dart';
import 'package:changa_app/features/chores/domain/usecases/delete_chore.dart';
import 'package:changa_app/features/chores/domain/usecases/update_chore.dart';
import 'package:changa_app/features/chores/presentation/cubit/add_chore_cubit.dart';

class MockCreateChore extends Mock implements CreateChore {}

class MockUpdateChore extends Mock implements UpdateChore {}

class MockDeleteChore extends Mock implements DeleteChore {}

const _me = ChoreAssignee(uid: 'me', name: 'You');
const _kevin = ChoreAssignee(uid: 'kevin', name: 'Kevin');

Chore _chore({String? seriesId, ChoreStatus status = ChoreStatus.pending}) {
  return Chore(
    id: 'c1',
    seriesId: seriesId,
    title: 'Dishes',
    difficulty: ChoreDifficulty.hard,
    assignedToUid: 'kevin',
    dueDate: DateTime(2026, 11, 13, 18),
    status: status,
    createdByUid: 'me',
    createdAt: DateTime(2026, 11, 1),
  );
}

void main() {
  late MockCreateChore create;
  late MockUpdateChore update;
  late MockDeleteChore delete;

  setUpAll(() {
    registerFallbackValue(
      NewChoreInput(
        householdId: 'h',
        title: 't',
        difficulty: ChoreDifficulty.easy,
        assignedToUid: 'u',
        dueDate: DateTime(2026),
        createdByUid: 'u',
      ),
    );
    registerFallbackValue(_chore());
  });

  setUp(() {
    create = MockCreateChore();
    update = MockUpdateChore();
    delete = MockDeleteChore();
  });

  AddChoreCubit build({Chore? editing}) => AddChoreCubit(
    createChore: create,
    updateChore: update,
    deleteChore: delete,
    householdId: 'home',
    meUid: 'me',
    assignees: const [_me, _kevin],
    editing: editing,
    clock: () => DateTime(2026, 11, 11, 9),
  );

  group('new chore', () {
    test('starts as a medium chore for me, due today', () {
      final state = build().state;

      expect(state.isEdit, isFalse);
      expect(state.difficulty, ChoreDifficulty.medium);
      expect(state.assigneeUid, 'me');
      expect(state.dueDate, DateTime(2026, 11, 11));
      expect(state.rotate, isFalse);
      expect(state.canSubmit, isFalse);
    });

    test('falls back to the first housemate when I am not listed', () {
      final cubit = AddChoreCubit(
        createChore: create,
        updateChore: update,
        deleteChore: delete,
        householdId: 'home',
        meUid: 'ghost',
        assignees: const [_kevin],
      );

      expect(cubit.state.assigneeUid, 'kevin');
    });

    test(
      'a blank title cannot be saved and shows an error on submit',
      () async {
        final cubit = build()..titleChanged('   ');

        expect(cubit.state.canSubmit, isFalse);
        await cubit.submit();

        expect(cubit.state.titleError, isNotNull);
        verifyNever(() => create(any()));
      },
    );

    test('typing clears the title error', () async {
      final cubit = build();
      await cubit.submit();
      cubit.titleChanged('D');

      expect(cubit.state.titleError, isNull);
    });

    test('a title over the limit is not valid', () {
      final cubit = build()
        ..titleChanged('x' * (AddChoreCubit.maxTitleLength + 1));

      expect(cubit.state.canSubmit, isFalse);
    });

    test('only housemates can be picked', () {
      final cubit = build()..assigneeChanged('stranger');
      expect(cubit.state.assigneeUid, 'me');

      cubit.assigneeChanged('kevin');
      expect(cubit.state.assigneeUid, 'kevin');
    });

    test('the due date drops the time of day', () {
      final cubit = build()..dueDateChanged(DateTime(2026, 11, 14, 22, 30));

      expect(cubit.state.dueDate, DateTime(2026, 11, 14));
    });

    test('saves with everything from the form', () async {
      when(() => create(any()))
          .thenAnswer((_) async => Result<void>.success(null));
      final cubit = build()
        ..titleChanged('  Sweep  ')
        ..difficultyChanged(ChoreDifficulty.easy)
        ..assigneeChanged('kevin')
        ..rotateChanged(true);

      await cubit.submit();

      final input =
          verify(() => create(captureAny())).captured.single as NewChoreInput;
      expect(input.householdId, 'home');
      expect(input.title, 'Sweep');
      expect(input.difficulty, ChoreDifficulty.easy);
      expect(input.assignedToUid, 'kevin');
      expect(input.createdByUid, 'me');
      expect(input.dueDate, DateTime(2026, 11, 11));
      expect(input.rotate, isTrue);
      expect(cubit.state.status, AddChoreStatus.success);
      expect(cubit.state.message, 'Chore added.');
    });

    test('shows the reason when saving fails', () async {
      when(() => create(any())).thenAnswer(
        (_) async =>
            Result<void>.failure(const ValidationFailure('Not a member.')),
      );
      final cubit = build()..titleChanged('Sweep');

      await cubit.submit();

      expect(cubit.state.status, AddChoreStatus.failure);
      expect(cubit.state.message, 'Not a member.');
      expect(cubit.state.canSubmit, isTrue);
    });
  });

  group('editing', () {
    test('loads the existing chore', () {
      final state = build(editing: _chore()).state;

      expect(state.isEdit, isTrue);
      expect(state.title, 'Dishes');
      expect(state.difficulty, ChoreDifficulty.hard);
      expect(state.assigneeUid, 'kevin');
      expect(state.dueDate, DateTime(2026, 11, 13));
      expect(state.isSeries, isFalse);
    });

    test('the rotation switch is ignored once the chore exists', () {
      final cubit = build(editing: _chore())..rotateChanged(true);

      expect(cubit.state.rotate, isFalse);
    });

    test('updates the same chore with the new values', () async {
      when(() => update(any(), any()))
          .thenAnswer((_) async => Result<void>.success(null));
      final cubit = build(editing: _chore())
        ..titleChanged('Dishes and pots')
        ..difficultyChanged(ChoreDifficulty.medium);

      await cubit.submit();

      final saved =
          verify(() => update('home', captureAny())).captured.single as Chore;
      expect(saved.id, 'c1');
      expect(saved.title, 'Dishes and pots');
      expect(saved.difficulty, ChoreDifficulty.medium);
      expect(cubit.state.message, 'Chore updated.');
      verifyNever(() => create(any()));
    });

    test('a finished chore is locked', () async {
      final cubit = build(editing: _chore(status: ChoreStatus.done));

      expect(cubit.state.isLocked, isTrue);
      expect(cubit.state.canSubmit, isFalse);
      await cubit.submit();

      verifyNever(() => update(any(), any()));
    });

    test('deleting removes only this chore by default', () async {
      when(() => delete(any(), any(), wholeSeries: any(named: 'wholeSeries')))
          .thenAnswer((_) async => Result<void>.success(null));
      final cubit = build(editing: _chore(seriesId: 's1'));

      await cubit.delete();

      verify(() => delete('home', 'c1', wholeSeries: false)).called(1);
      expect(cubit.state.message, 'Chore deleted.');
    });

    test('deleting can remove the whole rotation', () async {
      when(() => delete(any(), any(), wholeSeries: any(named: 'wholeSeries')))
          .thenAnswer((_) async => Result<void>.success(null));
      final cubit = build(editing: _chore(seriesId: 's1'));

      await cubit.delete(wholeSeries: true);

      verify(() => delete('home', 'c1', wholeSeries: true)).called(1);
    });

    test('there is nothing to delete on a new chore', () async {
      final cubit = build();

      await cubit.delete();

      verifyNever(
        () => delete(any(), any(), wholeSeries: any(named: 'wholeSeries')),
      );
    });
  });
}
