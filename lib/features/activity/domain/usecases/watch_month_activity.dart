import '../entities/activity.dart';
import '../repositories/activity_repository.dart';

class WatchMonthActivity {
  final ActivityRepository repository;
  WatchMonthActivity(this.repository);

  Stream<List<Activity>> call({
    required String householdId,
    required DateTime month,
  }) => repository.watchMonth(householdId, month);
}
