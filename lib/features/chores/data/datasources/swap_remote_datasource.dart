import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:changa_app/core/constants/firestore_paths.dart';
import 'package:changa_app/features/activity/data/activity_writer.dart';
import 'package:changa_app/features/activity/domain/entities/activity.dart';
import 'package:changa_app/features/chores/data/chore_exceptions.dart';
import 'package:changa_app/features/chores/data/models/chore_model.dart';
import 'package:changa_app/features/chores/data/models/swap_request_model.dart';
import 'package:changa_app/features/chores/domain/entities/chore.dart';
import 'package:changa_app/features/chores/domain/entities/swap_request.dart';
import 'package:changa_app/features/notifications/data/notification_templates.dart';
import 'package:changa_app/features/notifications/data/notification_writer.dart';

class SwapRemoteDataSource {
  SwapRemoteDataSource(
    this._db,
    this._auth,
    this._activity,
    this._notifications,
  );

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final ActivityWriter _activity;
  final NotificationWriter _notifications;

  CollectionReference<Map<String, dynamic>> _swaps(String householdId) =>
      _db.collection(FirestorePaths.swapRequests(householdId));

  CollectionReference<Map<String, dynamic>> _chores(String householdId) =>
      _db.collection(FirestorePaths.chores(householdId));

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw const ChoreRuleException.permission(
        'Please sign in again to continue.',
      );
    }
    return uid;
  }

  /// Open requests addressed to [uid], newest first.
  Stream<List<SwapRequestModel>> watchIncoming(String householdId, String uid) {
    return _swaps(householdId)
        .where(SwapRequestFields.toUid, isEqualTo: uid)
        .where(SwapRequestFields.status, isEqualTo: SwapStatus.pending.name)
        .orderBy(SwapRequestFields.createdAt, descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(SwapRequestModel.fromFirestore).toList());
  }

  Future<void> request({
    required String householdId,
    required String choreId,
    required String toUid,
    String? note,
  }) async {
    final me = _uid;
    if (toUid == me) {
      throw const ChoreRuleException.validation(
        'Pick a housemate to swap with.',
      );
    }

    final choreSnap = await _chores(householdId).doc(choreId).get();
    if (!choreSnap.exists) {
      throw const ChoreRuleException.notFound(
        'That chore is no longer available.',
      );
    }
    final chore = ChoreModel.fromFirestore(choreSnap);
    if (chore.assignedToUid != me) {
      throw const ChoreRuleException.permission(
        'You can only swap chores that are assigned to you.',
      );
    }
    if (chore.status == ChoreStatus.done) {
      throw const ChoreRuleException.validation('This chore is already done.');
    }

    final target = await _db
        .doc(FirestorePaths.member(householdId, toUid))
        .get();
    if (!target.exists) {
      throw const ChoreRuleException.validation(
        'Please pick someone who is in your household.',
      );
    }

    // One open request per chore. Filtering on fromUid keeps the query
    // inside what the security rules allow a member to read.
    final open = await _swaps(householdId)
        .where(SwapRequestFields.fromUid, isEqualTo: me)
        .where(SwapRequestFields.choreId, isEqualTo: choreId)
        .where(SwapRequestFields.status, isEqualTo: SwapStatus.pending.name)
        .limit(1)
        .get();
    if (open.docs.isNotEmpty) {
      throw const ChoreRuleException.validation(
        'A swap request is already open for this chore.',
      );
    }

    final name = await _firstName(me);
    final batch = _db.batch();

    batch.set(
      _swaps(householdId).doc(),
      SwapRequestModel.createMap(
        choreId: choreId,
        fromUid: me,
        toUid: toUid,
        note: note,
      ),
    );
    _notifications.addToBatch(
      batch: batch,
      householdId: householdId,
      recipientUid: toUid,
      actorUid: me,
      type: 'swap_request',
      message: NotificationTemplates.swapRequest(
        name: name,
        chore: chore.title,
      ),
      refId: choreId,
    );
    _activity.addToBatch(
      batch,
      householdId: householdId,
      type: ActivityType.swapRequested,
      actorUid: me,
      targetUid: toUid,
      refId: choreId,
    );

    await batch.commit();
  }

  Future<void> respond({
    required String householdId,
    required String requestId,
    required bool accept,
  }) async {
    final me = _uid;
    final name = await _firstName(me);
    final requestRef = _swaps(householdId).doc(requestId);

    await _db.runTransaction((tx) async {
      final requestSnap = await tx.get(requestRef);
      if (!requestSnap.exists) {
        throw const ChoreRuleException.notFound(
          'That swap request is no longer available.',
        );
      }
      final request = SwapRequestModel.fromFirestore(requestSnap);
      if (request.toUid != me) {
        throw const ChoreRuleException.permission(
          'This request was not sent to you.',
        );
      }
      if (request.status != SwapStatus.pending) {
        throw const ChoreRuleException.validation(
          'This request has already been answered.',
        );
      }

      // All reads first, then the writes.
      if (accept) {
        final choreRef = _chores(householdId).doc(request.choreId);
        final choreSnap = await tx.get(choreRef);
        if (!choreSnap.exists) {
          throw const ChoreRuleException.notFound(
            'That chore is no longer available.',
          );
        }
        final chore = ChoreModel.fromFirestore(choreSnap);
        if (chore.status == ChoreStatus.done ||
            chore.assignedToUid != request.fromUid) {
          throw const ChoreRuleException.validation(
            'This chore has changed, so the swap can’t go ahead.',
          );
        }

        tx.update(choreRef, {ChoreFields.assignedToUid: me});
        _activity.addToTransaction(
          tx,
          householdId: householdId,
          type: ActivityType.swapAccepted,
          actorUid: me,
          targetUid: request.fromUid,
          refId: request.choreId,
        );
      }

      tx.update(requestRef, {
        SwapRequestFields.status:
            (accept ? SwapStatus.accepted : SwapStatus.declined).name,
      });
      _notifications.addToTransaction(
        transaction: tx,
        householdId: householdId,
        recipientUid: request.fromUid,
        actorUid: me,
        type: 'swap_response',
        message: NotificationTemplates.swapResponse(
          name: name,
          accepted: accept,
        ),
        refId: request.choreId,
      );
    });
  }

  Future<void> cancel(String householdId, String requestId) async {
    final me = _uid;
    final ref = _swaps(householdId).doc(requestId);
    final snap = await ref.get();
    if (!snap.exists) {
      throw const ChoreRuleException.notFound(
        'That swap request is no longer available.',
      );
    }

    final request = SwapRequestModel.fromFirestore(snap);
    if (request.fromUid != me) {
      throw const ChoreRuleException.permission(
        'Only the person who asked can cancel a request.',
      );
    }
    if (request.status != SwapStatus.pending) {
      throw const ChoreRuleException.validation(
        'This request has already been answered.',
      );
    }

    await ref.update({SwapRequestFields.status: SwapStatus.cancelled.name});
  }

  /// First name only, which is how notifications address people.
  Future<String> _firstName(String uid) async {
    final snap = await _db.doc(FirestorePaths.user(uid)).get();
    final full = (snap.data()?[UserFields.fullName] as String?)?.trim() ?? '';
    return full.isEmpty ? 'A housemate' : full.split(' ').first;
  }
}
