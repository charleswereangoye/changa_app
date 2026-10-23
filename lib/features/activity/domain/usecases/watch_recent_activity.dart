import '../entities/activity.dart';
import '../repositories/activity_repository.dart';

class WatchRecentActivity {
  final ActivityRepository repository;
  WatchRecentActivity(this.repository);

  Stream<List<Activity>> call({required String householdId, int limit = 5}) =>
      repository.watchRecent(householdId, limit: limit);
}
