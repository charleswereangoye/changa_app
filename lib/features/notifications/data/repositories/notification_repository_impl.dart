import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_datasource.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  const NotificationRepositoryImpl(this._remoteDataSource, this._auth);

  final NotificationRemoteDataSource _remoteDataSource;
  final FirebaseAuth _auth;

  @override
  Stream<List<AppNotification>> watchUnread(String uid) async* {
    try {
      final currentUid = _requireUid(expectedUid: uid);
      final householdId = await _remoteDataSource.getHouseholdId(currentUid);

      if (householdId == null || householdId.isEmpty) {
        yield const <AppNotification>[];
        return;
      }

      yield* _remoteDataSource
          .watchUnread(householdId: householdId, uid: currentUid)
          .map(
            (models) => List<AppNotification>.unmodifiable(
              models.map((model) => model.toEntity()),
            ),
          );
    } catch (error, stackTrace) {
      // Surface the failure instead of showing an incorrect empty inbox.
      yield* Stream<List<AppNotification>>.error(
        _mapFailure(error),
        stackTrace,
      );
    }
  }

  @override
  Future<Result<void>> markRead(String notificationId) {
    return _perform(() async {
      if (notificationId.trim().isEmpty) {
        throw const NotificationDataException(
          ValidationFailure('Choose a notification to mark as read.'),
        );
      }

      final uid = _requireUid();
      final householdId = await _requireHouseholdId(uid);

      await _remoteDataSource.markRead(
        householdId: householdId,
        uid: uid,
        notificationId: notificationId,
      );
    });
  }

  @override
  Future<Result<void>> markAllRead(String uid) {
    return _perform(() async {
      final currentUid = _requireUid(expectedUid: uid);
      final householdId = await _requireHouseholdId(currentUid);

      await _remoteDataSource.markAllRead(
        householdId: householdId,
        uid: currentUid,
      );
    });
  }

  String _requireUid({String? expectedUid}) {
    final uid = _auth.currentUser?.uid;

    if (uid == null) {
      throw const NotificationDataException(
        AuthFailure('Please sign in to view notifications.'),
      );
    }

    if (expectedUid != null && expectedUid != uid) {
      throw const NotificationDataException(
        PermissionFailure('You can only access your own notifications.'),
      );
    }

    return uid;
  }

  Future<String> _requireHouseholdId(String uid) async {
    final householdId = await _remoteDataSource.getHouseholdId(uid);

    if (householdId == null || householdId.isEmpty) {
      throw const NotificationDataException(
        ValidationFailure('Join a household to access notifications.'),
      );
    }

    return householdId;
  }

  Future<Result<void>> _perform(Future<void> Function() operation) async {
    try {
      await operation();
      return Result<void>.success(null);
    } catch (error) {
      return Result<void>.failure(_mapFailure(error));
    }
  }

  Failure _mapFailure(Object error) {
    if (error is NotificationDataException) {
      return error.failure;
    }

    if (error is Failure) {
      return error;
    }

    if (error is FirebaseException) {
      return switch (error.code) {
        'permission-denied' => const PermissionFailure(),
        'unauthenticated' => const AuthFailure(
          'Please sign in to view notifications.',
        ),
        'unavailable' ||
        'network-request-failed' ||
        'deadline-exceeded' => const NetworkFailure(),
        'not-found' => const NotFoundFailure(),
        'failed-precondition' => const UnknownFailure(
          'Notifications are not available yet. Please try again later.',
        ),
        _ => const UnknownFailure(),
      };
    }

    return const UnknownFailure();
  }
}
