import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:changa_app/core/error/failures.dart';
import 'package:changa_app/core/error/result.dart';
import 'package:changa_app/features/chores/data/chore_exceptions.dart';
import 'package:changa_app/features/chores/data/datasources/chore_remote_datasource.dart';
import 'package:changa_app/features/chores/data/datasources/swap_remote_datasource.dart';
import 'package:changa_app/features/chores/data/repositories/chore_repository_impl.dart';

class MockChoreSource extends Mock implements ChoreRemoteDataSource {}

class MockSwapSource extends Mock implements SwapRemoteDataSource {}

void main() {
  late MockChoreSource chores;
  late MockSwapSource swaps;
  late ChoreRepositoryImpl repository;

  setUp(() {
    chores = MockChoreSource();
    swaps = MockSwapSource();
    repository = ChoreRepositoryImpl(chores, swaps);
  });

  Future<Result<void>> complete() => repository.completeChore('h1', 'c1');

  test('a finished call becomes a success', () async {
    when(() => chores.complete('h1', 'c1')).thenAnswer((_) async {});

    expect((await complete()).isSuccess, isTrue);
  });

  group('rule errors become friendly failures', () {
    test('validation', () async {
      when(() => chores.complete('h1', 'c1'))
          .thenThrow(const ChoreRuleException.validation('Already done.'));

      final failure = (await complete()).failureOrNull;
      expect(failure, isA<ValidationFailure>());
      expect(failure?.message, 'Already done.');
    });

    test('permission', () async {
      when(() => chores.complete('h1', 'c1'))
          .thenThrow(const ChoreRuleException.permission('Not yours.'));

      expect((await complete()).failureOrNull, isA<PermissionFailure>());
    });

    test('not found', () async {
      when(() => chores.complete('h1', 'c1'))
          .thenThrow(const ChoreRuleException.notFound('Gone.'));

      expect((await complete()).failureOrNull, isA<NotFoundFailure>());
    });
  });

  group('Firebase errors', () {
    Future<Failure?> failWith(String code) async {
      when(() => chores.complete('h1', 'c1'))
          .thenThrow(FirebaseException(plugin: 'cloud_firestore', code: code));
      return (await complete()).failureOrNull;
    }

    test('permission denied', () async {
      expect(await failWith('permission-denied'), isA<PermissionFailure>());
    });

    test('network trouble', () async {
      expect(await failWith('unavailable'), isA<NetworkFailure>());
    });

    test('anything else is unknown', () async {
      expect(await failWith('aborted'), isA<UnknownFailure>());
    });
  });

  test('a surprise error is reported, not thrown', () async {
    when(() => chores.complete('h1', 'c1')).thenThrow(StateError('boom'));

    expect((await complete()).failureOrNull, isA<UnknownFailure>());
  });

  test('swap calls go through the same guard', () async {
    when(() => swaps.cancel('h1', 'r1'))
        .thenThrow(const ChoreRuleException.permission('Only the asker.'));

    final result = await repository.cancelSwap('h1', 'r1');

    expect(result.failureOrNull, isA<PermissionFailure>());
  });
}
