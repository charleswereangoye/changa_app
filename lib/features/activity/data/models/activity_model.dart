import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:changa_app/core/constants/firestore_paths.dart';

import '../../domain/entities/activity.dart';

class ActivityModel extends Activity {
  const ActivityModel({
    required super.id,
    required super.type,
    required super.actorUid,
    super.targetUid,
    super.refId,
    super.amount,
    required super.createdAt,
  });

  factory ActivityModel.fromJson(Map<String, dynamic> json, String id) {
    return ActivityModel(
      id: id,
      type: ActivityType.values.firstWhere(
        (e) => e.name == json[ActivityFields.type],
        orElse: () => ActivityType.expenseAdded, // Safe fallback
      ),
      actorUid: json[ActivityFields.actorUid] as String,
      targetUid: json[ActivityFields.targetUid] as String?,
      refId: json[ActivityFields.refId] as String?,
      amount: json[ActivityFields.amount] as int?,
      createdAt: (json[ActivityFields.createdAt] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ActivityFields.type: type.name,
      ActivityFields.actorUid: actorUid,
      if (targetUid != null) ActivityFields.targetUid: targetUid,
      if (refId != null) ActivityFields.refId: refId,
      if (amount != null) ActivityFields.amount: amount,
      ActivityFields.createdAt: Timestamp.fromDate(createdAt),
    };
  }
}
