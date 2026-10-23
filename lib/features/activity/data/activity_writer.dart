import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:changa_app/core/constants/firestore_paths.dart';
import 'package:changa_app/features/activity/data/models/activity_model.dart';
import 'package:changa_app/features/activity/domain/entities/activity.dart';

class ActivityWriter {
  final FirebaseFirestore _firestore;

  ActivityWriter({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  ActivityModel _createModel({
    required ActivityType type,
    required String actorUid,
    String? targetUid,
    String? refId,
    int? amount,
  }) {
    // Generate a secure unique ID for the new activity
    final id = _firestore.collection('temp_id_generator').doc().id;
    return ActivityModel(
      id: id,
      type: type,
      actorUid: actorUid,
      targetUid: targetUid,
      refId: refId,
      amount: amount,
      createdAt: DateTime.now(),
    );
  }

  void addToBatch(
    WriteBatch batch, {
    required String householdId,
    required ActivityType type,
    required String actorUid,
    String? targetUid,
    String? refId,
    int? amount,
  }) {
    final activity = _createModel(
      type: type, actorUid: actorUid, targetUid: targetUid, refId: refId, amount: amount,
    );
    final docRef = _firestore.doc(FirestorePaths.activity(householdId, activity.id));
    batch.set(docRef, activity.toJson());
  }

  void addToTransaction(
    Transaction tx, {
    required String householdId,
    required ActivityType type,
    required String actorUid,
    String? targetUid,
    String? refId,
    int? amount,
  }) {
    final activity = _createModel(
      type: type, actorUid: actorUid, targetUid: targetUid, refId: refId, amount: amount,
    );
    final docRef = _firestore.doc(FirestorePaths.activity(householdId, activity.id));
    tx.set(docRef, activity.toJson());
  }
}