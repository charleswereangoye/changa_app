import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:changa_app/core/constants/firestore_paths.dart';
import 'package:changa_app/core/utils/date_helpers.dart';
import 'package:changa_app/features/chores/domain/entities/chore.dart';

class ChoreModel {
  const ChoreModel({
    required this.id,
    required this.title,
    required this.difficulty,
    required this.assignedToUid,
    required this.dueDate,
    required this.status,
    required this.createdByUid,
    required this.createdAt,
    this.seriesId,
    this.description,
    this.completedAt,
    this.creditsAwarded,
  });

  final String id;
  final String? seriesId;
  final String title;
  final String? description;
  final ChoreDifficulty difficulty;
  final String assignedToUid;
  final DateTime dueDate;
  final ChoreStatus status;
  final DateTime? completedAt;
  final int? creditsAwarded;
  final String createdByUid;
  final DateTime createdAt;

  factory ChoreModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final status =
        ChoreStatus.values.asNameMap()[data[ChoreFields.status]] ??
        ChoreStatus.pending;

    return ChoreModel(
      id: doc.id,
      seriesId: data[ChoreFields.seriesId] as String?,
      title: data[ChoreFields.title] as String? ?? '',
      description: data[ChoreFields.description] as String?,
      difficulty:
          ChoreDifficulty.values.asNameMap()[data[ChoreFields.difficulty]] ??
          ChoreDifficulty.easy,
      assignedToUid: data[ChoreFields.assignedToUid] as String? ?? '',
      dueDate: _toDate(data[ChoreFields.dueDate]) ?? DateTime.now(),
      status: status,
      // A fresh server timestamp reads back as null until it syncs.
      completedAt:
          _toDate(data[ChoreFields.completedAt]) ??
          (status == ChoreStatus.done ? DateTime.now() : null),
      creditsAwarded: (data[ChoreFields.creditsAwarded] as num?)?.toInt(),
      createdByUid: data[ChoreFields.createdByUid] as String? ?? '',
      createdAt: _toDate(data[ChoreFields.createdAt]) ?? DateTime.now(),
    );
  }

  Chore toEntity() => Chore(
    id: id,
    seriesId: seriesId,
    title: title,
    description: description,
    difficulty: difficulty,
    assignedToUid: assignedToUid,
    dueDate: dueDate,
    status: status,
    completedAt: completedAt,
    creditsAwarded: creditsAwarded,
    createdByUid: createdByUid,
    createdAt: createdAt,
  );

  factory ChoreModel.fromEntity(Chore chore) => ChoreModel(
    id: chore.id,
    seriesId: chore.seriesId,
    title: chore.title,
    description: chore.description,
    difficulty: chore.difficulty,
    assignedToUid: chore.assignedToUid,
    dueDate: chore.dueDate,
    status: chore.status,
    completedAt: chore.completedAt,
    creditsAwarded: chore.creditsAwarded,
    createdByUid: chore.createdByUid,
    createdAt: chore.createdAt,
  );

  /// Every field is written, nulls included, so each document matches the ERD.
  static Map<String, dynamic> createMap({
    required String title,
    required ChoreDifficulty difficulty,
    required String assignedToUid,
    required DateTime dueDate,
    required String createdByUid,
    String? description,
    String? seriesId,
  }) {
    return {
      ChoreFields.seriesId: seriesId,
      ChoreFields.title: title.trim(),
      ChoreFields.description: _clean(description),
      ChoreFields.difficulty: difficulty.name,
      ChoreFields.assignedToUid: assignedToUid,
      // Stored at midnight so "due on a day" is a simple range query.
      ChoreFields.dueDate: Timestamp.fromDate(DateHelpers.startOfDay(dueDate)),
      ChoreFields.status: ChoreStatus.pending.name,
      ChoreFields.completedAt: null,
      ChoreFields.creditsAwarded: null,
      ChoreFields.createdByUid: createdByUid,
      ChoreFields.createdAt: FieldValue.serverTimestamp(),
    };
  }

  /// Only the fields the edit form can change.
  Map<String, dynamic> toEditMap() => {
    ChoreFields.title: title.trim(),
    ChoreFields.description: _clean(description),
    ChoreFields.difficulty: difficulty.name,
    ChoreFields.assignedToUid: assignedToUid,
    ChoreFields.dueDate: Timestamp.fromDate(DateHelpers.startOfDay(dueDate)),
  };

  static DateTime? _toDate(Object? value) =>
      value is Timestamp ? value.toDate() : null;

  static String? _clean(String? text) {
    final trimmed = text?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}
