import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../domain/entities/app_notification.dart';

class NotificationModel extends AppNotification {
  const NotificationModel({
    required super.id,
    required super.recipientUid,
    required super.actorUid,
    required super.type,
    required super.title,
    required super.body,
    required super.read,
    required super.createdAt,
    super.refId,
  });

  factory NotificationModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    if (data == null) {
      throw StateError('Notification document ${document.id} has no data.');
    }

    return NotificationModel(
      id: document.id,
      recipientUid: data[NotificationFields.recipientUid] as String,
      actorUid: data[NotificationFields.actorUid] as String,
      type: data[NotificationFields.type] as String,
      title: data[NotificationFields.title] as String,
      body: data[NotificationFields.body] as String,
      refId: data[NotificationFields.refId] as String?,
      read: data[NotificationFields.read] as bool,
      createdAt:
          (data[NotificationFields.createdAt] as Timestamp?)?.toDate() ??
          DateTime.now(),
    );
  }

  factory NotificationModel.fromEntity(AppNotification notification) {
    return NotificationModel(
      id: notification.id,
      recipientUid: notification.recipientUid,
      actorUid: notification.actorUid,
      type: notification.type,
      title: notification.title,
      body: notification.body,
      refId: notification.refId,
      read: notification.read,
      createdAt: notification.createdAt,
    );
  }

  AppNotification toEntity() {
    return AppNotification(
      id: id,
      recipientUid: recipientUid,
      actorUid: actorUid,
      type: type,
      title: title,
      body: body,
      refId: refId,
      read: read,
      createdAt: createdAt,
    );
  }
}
