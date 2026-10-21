// Owner: D - Person D (Debts, Settling, Nudges, Notifications, Release Build)
// Description: Helper class writing notifications inside atomic batches/transactions

// TODO(D): Implement NotificationWriter according to project specification

// Owner: D
// Adds notification writes to an existing batch or transaction.

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_paths.dart';
import 'notification_templates.dart';

class NotificationWriter {
  const NotificationWriter(this._firestore);

  final FirebaseFirestore _firestore;

  /// Adds a notification to the caller's batch.
  ///
  /// The caller commits the batch after adding all related writes.
  /// Returns the generated notification ID.
  String addToBatch({
    required WriteBatch batch,
    required String householdId,
    required String recipientUid,
    required String actorUid,
    required String type,
    required NotificationMessage message,
    String? refId,
  }) {
    final document = _firestore
        .collection(FirestorePaths.notifications(householdId))
        .doc();

    batch.set(
      document,
      _notificationData(
        recipientUid: recipientUid,
        actorUid: actorUid,
        type: type,
        message: message,
        refId: refId,
      ),
    );

    return document.id;
  }

  /// Adds a notification to the caller's transaction.
  ///
  /// The caller must finish all transaction reads before calling this.
  /// Returns the generated notification ID.
  String addToTransaction({
    required Transaction transaction,
    required String householdId,
    required String recipientUid,
    required String actorUid,
    required String type,
    required NotificationMessage message,
    String? refId,
  }) {
    final document = _firestore
        .collection(FirestorePaths.notifications(householdId))
        .doc();

    transaction.set(
      document,
      _notificationData(
        recipientUid: recipientUid,
        actorUid: actorUid,
        type: type,
        message: message,
        refId: refId,
      ),
    );

    return document.id;
  }

  Map<String, dynamic> _notificationData({
    required String recipientUid,
    required String actorUid,
    required String type,
    required NotificationMessage message,
    String? refId,
  }) {
    return {
      NotificationFields.recipientUid: recipientUid,
      NotificationFields.actorUid: actorUid,
      NotificationFields.type: type,
      NotificationFields.title: message.title,
      NotificationFields.body: message.body,
      NotificationFields.refId: refId,
      NotificationFields.read: false,
      NotificationFields.createdAt: FieldValue.serverTimestamp(),
    };
  }
}
