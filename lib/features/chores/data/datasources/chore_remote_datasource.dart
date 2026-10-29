import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:changa_app/core/constants/app_constants.dart';
import 'package:changa_app/core/constants/firestore_paths.dart';
import 'package:changa_app/core/utils/date_helpers.dart';
import 'package:changa_app/features/activity/data/activity_writer.dart';
import 'package:changa_app/features/activity/domain/entities/activity.dart';
import 'package:changa_app/features/chores/data/chore_exceptions.dart';
import 'package:changa_app/features/chores/data/models/chore_model.dart';
import 'package:changa_app/features/chores/domain/entities/chore.dart';
import 'package:changa_app/features/chores/domain/entities/new_chore_input.dart';
import 'package:changa_app/features/chores/domain/logic/rotation_planner.dart';

class ChoreRemoteDataSource {
  ChoreRemoteDataSource(this._db, this._auth, this._activity);

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final ActivityWriter _activity;

  // Firestore caps a batch at 500 writes, so big updates go in slices.
  static const _batchSize = 400;

  CollectionReference<Map<String, dynamic>> _chores(String householdId) =>
      _db.collection(FirestorePaths.chores(householdId));

  DocumentReference<Map<String, dynamic>> _member(
    String householdId,
    String uid,
  ) => _db.doc(FirestorePaths.member(householdId, uid));

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw const ChoreRuleException.permission(
        'Please sign in again to continue.',
      );
    }
    return uid;
  }

  Stream<List<ChoreModel>> watchForDay(String householdId, DateTime day) {
    return _chores(householdId)
        .where(
          ChoreFields.dueDate,
          isGreaterThanOrEqualTo: Timestamp.fromDate(
            DateHelpers.startOfDay(day),
          ),
        )
        .where(
          ChoreFields.dueDate,
          isLessThanOrEqualTo: Timestamp.fromDate(DateHelpers.endOfDay(day)),
        )
        .snapshots()
        .map(_toSortedModels);
  }

  Stream<List<ChoreModel>> watchAll(String householdId) {
    final from = DateHelpers.addDays(
      DateHelpers.startOfDay(DateTime.now()),
      -AppConstants.harmonyChoreWindowDays,
    );
    return _chores(householdId)
        .where(
          ChoreFields.dueDate,
          isGreaterThanOrEqualTo: Timestamp.fromDate(from),
        )
        .snapshots()
        .map(_toSortedModels);
  }

  Future<void> create(NewChoreInput input) async {
    final chores = _chores(input.householdId);

    if (!input.rotate) {
      await chores.add(
        ChoreModel.createMap(
          title: input.title,
          description: input.description,
          difficulty: input.difficulty,
          assignedToUid: input.assignedToUid,
          dueDate: input.dueDate,
          createdByUid: input.createdByUid,
        ),
      );
      return;
    }

    final orderedUids = await _memberUidsByJoinDate(input.householdId);
    if (!orderedUids.contains(input.assignedToUid)) {
      throw const ChoreRuleException.validation(
        'Please pick someone who is in your household.',
      );
    }

    // All four weeks are written together, so there is no background job
    final seriesId = chores.doc().id;
    final slots = RotationPlanner.plan(
      firstDueDate: input.dueDate,
      startingUid: input.assignedToUid,
      orderedUids: orderedUids,
    );

    final batch = _db.batch();
    for (final slot in slots) {
      batch.set(
        chores.doc(),
        ChoreModel.createMap(
          title: input.title,
          description: input.description,
          difficulty: input.difficulty,
          assignedToUid: slot.assigneeUid,
          dueDate: slot.dueDate,
          createdByUid: input.createdByUid,
          seriesId: seriesId,
        ),
      );
    }
    await batch.commit();
  }

  Future<void> update(String householdId, ChoreModel chore) async {
    final ref = _chores(householdId).doc(chore.id);

    // Read, check and write in one transaction. If the chore is completed
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) {
        throw const ChoreRuleException.notFound(
          'That chore is no longer available.',
        );
      }
      if (snap.data()?[ChoreFields.status] == ChoreStatus.done.name) {
        throw const ChoreRuleException.validation(
          'Finished chores can’t be edited.',
        );
      }
      tx.update(ref, chore.toEditMap());
    });
  }

  Future<void> delete(
    String householdId,
    String choreId, {
    required bool wholeSeries,
  }) async {
    final ref = _chores(householdId).doc(choreId);
    if (!wholeSeries) {
      await ref.delete();
      return;
    }

    final seriesId = (await ref.get()).data()?[ChoreFields.seriesId] as String?;
    if (seriesId == null) {
      await ref.delete();
      return;
    }

    // Finished weeks stay as history, only what is still ahead is removed.
    final open = await _chores(householdId)
        .where(ChoreFields.seriesId, isEqualTo: seriesId)
        .where(ChoreFields.status, isEqualTo: ChoreStatus.pending.name)
        .get();
    await _commitInSlices(
      open.docs,
      (batch, doc) => batch.delete(doc.reference),
    );
  }

  Future<void> complete(String householdId, String choreId) async {
    final uid = _uid;
    final ref = _chores(householdId).doc(choreId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) {
        throw const ChoreRuleException.notFound(
          'That chore is no longer available.',
        );
      }

      final chore = ChoreModel.fromFirestore(snap);
      if (chore.assignedToUid != uid) {
        throw const ChoreRuleException.permission(
          'Only the person assigned can tick this chore.',
        );
      }
      if (chore.status == ChoreStatus.done) {
        throw const ChoreRuleException.validation(
          'This chore is already done.',
        );
      }

      // Late or on time, the effort earns credits. Harmony tracks timing.
      final credits = chore.difficulty.credits;

      tx.update(ref, {
        ChoreFields.status: ChoreStatus.done.name,
        ChoreFields.completedAt: FieldValue.serverTimestamp(),
        ChoreFields.creditsAwarded: credits,
      });
      tx.update(_member(householdId, uid), {
        MemberFields.credits: FieldValue.increment(credits),
      });
      _activity.addToTransaction(
        tx,
        householdId: householdId,
        type: ActivityType.choreCompleted,
        actorUid: uid,
        refId: choreId,
        amount: credits,
      );
    });
  }

  Future<void> reassign(
    String householdId,
    String fromUid,
    String toUid,
  ) async {
    final pending = await _chores(householdId)
        .where(ChoreFields.assignedToUid, isEqualTo: fromUid)
        .where(ChoreFields.status, isEqualTo: ChoreStatus.pending.name)
        .get();

    await _commitInSlices(
      pending.docs,
      (batch, doc) =>
          batch.update(doc.reference, {ChoreFields.assignedToUid: toUid}),
    );
  }

  Future<List<String>> _memberUidsByJoinDate(String householdId) async {
    final members = await _db
        .collection(FirestorePaths.members(householdId))
        .orderBy(MemberFields.joinedAt)
        .get();
    return members.docs.map((doc) => doc.id).toList();
  }

  Future<void> _commitInSlices(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    void Function(
      WriteBatch batch,
      QueryDocumentSnapshot<Map<String, dynamic>> doc,
    )
    write,
  ) async {
    for (var i = 0; i < docs.length; i += _batchSize) {
      final batch = _db.batch();
      for (final doc in docs.skip(i).take(_batchSize)) {
        write(batch, doc);
      }
      await batch.commit();
    }
  }

  List<ChoreModel> _toSortedModels(QuerySnapshot<Map<String, dynamic>> snap) {
    final models = snap.docs.map(ChoreModel.fromFirestore).toList();
    models.sort((a, b) {
      // Open chores first, then alphabetical
      final byStatus = a.status.index.compareTo(b.status.index);
      return byStatus != 0
          ? byStatus
          : a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
    return models;
  }
}
