//Remote data source for Activity feed collection

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:changa_app/core/constants/firestore_paths.dart';
import 'package:changa_app/features/activity/data/models/activity_model.dart';

abstract class ActivityRemoteDataSource {
  Stream<List<ActivityModel>> watchRecent(String householdId, {int limit = 5});
  Stream<List<ActivityModel>> watchMonth(String householdId, DateTime month);
}

class ActivityRemoteDataSourceImpl implements ActivityRemoteDataSource {
  final FirebaseFirestore _firestore;

  ActivityRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<ActivityModel>> watchRecent(
    String householdId, {
    int limit = 5,
  }) {
    final cleanHouseholdId = householdId.trim();
    if (cleanHouseholdId.isEmpty || limit <= 0) {
      return Stream.value(const <ActivityModel>[]);
    }

    return _firestore
        .collection(FirestorePaths.activities(cleanHouseholdId))
        .orderBy(ActivityFields.createdAt, descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => _sortModels(
            snapshot.docs.map((doc) => _tryFromDoc(doc.data(), doc.id)),
          ),
        );
  }

  @override
  Stream<List<ActivityModel>> watchMonth(
    String householdId,
    DateTime month,
  ) {
    final cleanHouseholdId = householdId.trim();
    if (cleanHouseholdId.isEmpty) {
      return Stream.value(const <ActivityModel>[]);
    }

    final startOfMonth = DateTime(month.year, month.month, 1);
    final startOfNextMonth = DateTime(month.year, month.month + 1, 1);

    return _firestore
        .collection(FirestorePaths.activities(cleanHouseholdId))
        .where(
          ActivityFields.createdAt,
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
        )
        .where(
          ActivityFields.createdAt,
          isLessThan: Timestamp.fromDate(startOfNextMonth),
        )
        .orderBy(ActivityFields.createdAt, descending: true)
        .snapshots()
        .map(
          (snapshot) => _sortModels(
            snapshot.docs.map((doc) => _tryFromDoc(doc.data(), doc.id)),
          ),
        );
  }

  ActivityModel? _tryFromDoc(dynamic data, String id) {
    if (data is! Map<String, dynamic>) return null;
    try {
      return ActivityModel.fromJson(data, id);
    } on FormatException {
      return null;
    }
  }

  List<ActivityModel> _sortModels(Iterable<ActivityModel?> items) {
    final models = items.whereType<ActivityModel>().toList();
    models.sort((a, b) {
      final dateOrder = b.createdAt.compareTo(a.createdAt);
      return dateOrder != 0 ? dateOrder : a.id.compareTo(b.id);
    });
    return models;
  }
}