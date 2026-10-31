import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/error/failures.dart';
import '../models/notification_model.dart';

/// The repository converts this into Result.failure.
class NotificationDataException implements Exception {
  const NotificationDataException(this.failure);

  final Failure failure;

  @override
  String toString() => 'NotificationDataException: ${failure.message}';
}

class NotificationRemoteDataSource {
  const NotificationRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  static const int _batchSize = 400;

  CollectionReference<Map<String, dynamic>> _notifications(String householdId) {
    return _firestore.collection(FirestorePaths.notifications(householdId));
  }

  /// Looks up the household of the signed-in user supplied by the repository.
  Future<String?> getHouseholdId(String uid) async {
    if (uid.isEmpty) {
      throw const NotificationDataException(
        ValidationFailure('Please sign in to view notifications.'),
      );
    }

    final user = await _firestore
        .doc(FirestorePaths.user(uid))
        .get(const GetOptions(source: Source.server));

    if (!user.exists) {
      throw const NotificationDataException(
        NotFoundFailure('Your profile could not be found.'),
      );
    }

    return user.data()?[UserFields.householdId] as String?;
  }

  /// Recipient-only query, newest notifications first.
  Stream<List<NotificationModel>> watchUnread({
    required String householdId,
    required String uid,
  }) {
    return _notifications(householdId)
        .where(NotificationFields.recipientUid, isEqualTo: uid)
        .where(NotificationFields.read, isEqualTo: false)
        .orderBy(NotificationFields.createdAt, descending: true)
        .snapshots()
        .map(
          (snapshot) => List<NotificationModel>.unmodifiable(
            snapshot.docs.map(NotificationModel.fromFirestore),
          ),
        );
  }

  /// Checks the recipient and changes only the read flag.
  Future<void> markRead({
    required String householdId,
    required String uid,
    required String notificationId,
  }) async {
    final reference = _firestore.doc(
      FirestorePaths.notification(householdId, notificationId),
    );

    await _firestore.runTransaction((transaction) async {
      final document = await transaction.get(reference);
      final data = document.data();

      if (data == null) {
        throw const NotificationDataException(
          NotFoundFailure('This notification is no longer available.'),
        );
      }

      if (data[NotificationFields.recipientUid] != uid) {
        throw const NotificationDataException(
          PermissionFailure('You can only update your own notifications.'),
        );
      }

      if (data[NotificationFields.read] == true) {
        return;
      }

      transaction.update(reference, {NotificationFields.read: true});
    });
  }

  /// Marks the currently unread items for this recipient as read.
  ///
  /// Notifications arriving after the query remain unread.
  Future<void> markAllRead({
    required String householdId,
    required String uid,
  }) async {
    final snapshot = await _notifications(householdId)
        .where(NotificationFields.recipientUid, isEqualTo: uid)
        .where(NotificationFields.read, isEqualTo: false)
        .get(const GetOptions(source: Source.server));

    for (var start = 0; start < snapshot.docs.length; start += _batchSize) {
      final batch = _firestore.batch();

      for (final document in snapshot.docs.skip(start).take(_batchSize)) {
        batch.update(document.reference, {NotificationFields.read: true});
      }

      await batch.commit();
    }
  }
}
