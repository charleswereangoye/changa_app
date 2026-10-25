import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:changa_app/core/constants/firestore_paths.dart';
import 'package:changa_app/features/chores/domain/entities/swap_request.dart';

class SwapRequestModel {
  const SwapRequestModel({
    required this.id,
    required this.choreId,
    required this.fromUid,
    required this.toUid,
    required this.status,
    required this.createdAt,
    this.note,
  });

  final String id;
  final String choreId;
  final String fromUid;
  final String toUid;
  final String? note;
  final SwapStatus status;
  final DateTime createdAt;

  factory SwapRequestModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    final created = data[SwapRequestFields.createdAt];

    return SwapRequestModel(
      id: doc.id,
      choreId: data[SwapRequestFields.choreId] as String? ?? '',
      fromUid: data[SwapRequestFields.fromUid] as String? ?? '',
      toUid: data[SwapRequestFields.toUid] as String? ?? '',
      note: data[SwapRequestFields.note] as String?,
      status:
          SwapStatus.values.asNameMap()[data[SwapRequestFields.status]] ??
          SwapStatus.pending,
      createdAt: created is Timestamp ? created.toDate() : DateTime.now(),
    );
  }

  SwapRequest toEntity() => SwapRequest(
    id: id,
    choreId: choreId,
    fromUid: fromUid,
    toUid: toUid,
    note: note,
    status: status,
    createdAt: createdAt,
  );

  static Map<String, dynamic> createMap({
    required String choreId,
    required String fromUid,
    required String toUid,
    String? note,
  }) {
    final trimmed = note?.trim();
    return {
      SwapRequestFields.choreId: choreId,
      SwapRequestFields.fromUid: fromUid,
      SwapRequestFields.toUid: toUid,
      SwapRequestFields.note: (trimmed == null || trimmed.isEmpty)
          ? null
          : trimmed,
      SwapRequestFields.status: SwapStatus.pending.name,
      SwapRequestFields.createdAt: FieldValue.serverTimestamp(),
    };
  }
}
