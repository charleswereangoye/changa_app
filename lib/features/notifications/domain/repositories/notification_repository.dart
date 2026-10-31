import '../../../../core/error/result.dart';
import '../entities/app_notification.dart';

abstract class NotificationRepository {
  /// Watches this recipient's unread notifications, newest first.
  ///
  /// The implementation scopes queries to the active household.
  Stream<List<AppNotification>> watchUnread(String uid);

  /// Marks one notification belonging to the signed-in recipient as read.
  Future<Result<void>> markRead(String notificationId);

  /// Marks the recipient's unread notifications as read.
  Future<Result<void>> markAllRead(String uid);
}
