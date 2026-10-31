import '../entities/app_notification.dart';
import '../repositories/notification_repository.dart';

class WatchUnreadNotifications {
  const WatchUnreadNotifications(this._repository);

  final NotificationRepository _repository;

  Stream<List<AppNotification>> call(String uid) {
    return _repository.watchUnread(uid);
  }
}
