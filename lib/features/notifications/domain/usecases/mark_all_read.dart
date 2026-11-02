import '../../../../core/error/result.dart';
import '../repositories/notification_repository.dart';

class MarkAllRead {
  const MarkAllRead(this._repository);

  final NotificationRepository _repository;

  Future<Result<void>> call(String uid) {
    return _repository.markAllRead(uid);
  }
}
