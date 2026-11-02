import '../../../../core/error/result.dart';
import '../repositories/notification_repository.dart';

class MarkNotificationRead {
  const MarkNotificationRead(this._repository);

  final NotificationRepository _repository;

  Future<Result<void>> call(String notificationId) {
    return _repository.markRead(notificationId);
  }
}
