// Connects debt use cases to Firestore through the data source.

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/debt.dart';
import '../../domain/repositories/debt_repository.dart';
import '../datasources/debt_remote_datasource.dart';

class DebtRepositoryImpl implements DebtRepository {
  const DebtRepositoryImpl(this._remoteDataSource, this._auth);

  final DebtRemoteDataSource _remoteDataSource;
  final FirebaseAuth _auth;

  @override
  Stream<List<Debt>> watchPendingDebts(String householdId) {
    return _withFriendlyErrors(
      _remoteDataSource.watchPendingDebts(householdId),
    );
  }

  @override
  Stream<List<Debt>> watchDebtsSince(String householdId, DateTime since) {
    return _withFriendlyErrors(
      _remoteDataSource.watchDebtsSince(householdId, since),
    );
  }

  @override
  Stream<List<Debt>> watchDebtsBetween(
    String householdId,
    String uidA,
    String uidB,
  ) {
    return _withFriendlyErrors(
      _remoteDataSource.watchDebtsBetween(householdId, uidA, uidB),
    );
  }

  @override
  Future<Result<void>> settleBetween({
    required String householdId,
    required String meUid,
    required String otherUid,
    required String method,
  }) {
    return _perform(
      actorUid: meUid,
      operation: () async {
        await _remoteDataSource.settleBetween(
          householdId: householdId,
          meUid: meUid,
          otherUid: otherUid,
          method: method,
        );

        return null;
      },
    );
  }

  @override
  Future<Result<void>> sendNudge({
    required String householdId,
    required String fromUid,
    required String toUid,
  }) {
    return _perform(
      actorUid: fromUid,
      operation: () => _remoteDataSource.sendNudge(
        householdId: householdId,
        fromUid: fromUid,
        toUid: toUid,
      ),
    );
  }

  Future<Result<void>> _perform({
    required String actorUid,
    required Future<Failure?> Function() operation,
  }) async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        return Result<void>.failure(
          const AuthFailure('Please sign in to continue.'),
        );
      }

      if (user.uid != actorUid) {
        return Result<void>.failure(const PermissionFailure());
      }

      final failure = await operation();

      if (failure != null) {
        return Result<void>.failure(failure);
      }

      return Result<void>.success(null);
    } catch (error) {
      return Result<void>.failure(_mapFailure(error));
    }
  }

  /// Keep stream errors visible instead of replacing them with empty debts.
  Stream<List<Debt>> _withFriendlyErrors(Stream<List<Debt>> source) {
    return source.transform(
      StreamTransformer<List<Debt>, List<Debt>>.fromHandlers(
        handleError: (error, stackTrace, sink) {
          sink.addError(_mapFailure(error), stackTrace);
        },
      ),
    );
  }

  Failure _mapFailure(Object error) {
    if (error is Failure) {
      return error;
    }

    if (error is FirebaseException) {
      return switch (error.code) {
        'permission-denied' => const PermissionFailure(),
        'unauthenticated' => const AuthFailure('Please sign in to continue.'),
        'unavailable' ||
        'network-request-failed' ||
        'deadline-exceeded' => const NetworkFailure(),
        'not-found' => const NotFoundFailure(),
        'failed-precondition' => const ValidationFailure(
          'This action is not available yet. Please try again later.',
        ),
        _ => const UnknownFailure(),
      };
    }

    if (error is FormatException) {
      return const ValidationFailure(
        'Some balance details need checking. Please try again later.',
      );
    }

    if (error is ArgumentError) {
      return const ValidationFailure(
        'Please check the selected housemate and payment method.',
      );
    }

    if (error is StateError) {
      return const ValidationFailure(
        'This balance could not be updated. Please try again later.',
      );
    }

    return const UnknownFailure();
  }
}
