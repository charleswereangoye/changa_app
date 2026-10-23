import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:changa_app/core/constants/firestore_paths.dart';

import 'models/activity_model.dart';

class ActivityWriter {
  final FirebaseFirestore _firestore;

  ActivityWriter({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Appends an activity to an existing [WriteBatch].
  void logActivity(
    WriteBatch batch, {
    required String householdId,
    required ActivityModel activity,
  }) {
    final docRef = _firestore.doc(
      FirestorePaths.activity(householdId, activity.id),
    );

    batch.set(docRef, activity.toJson());
  }
}
