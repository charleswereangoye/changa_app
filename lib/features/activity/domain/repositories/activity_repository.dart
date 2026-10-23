import '../entities/activity.dart';

abstract class ActivityRepository {
  Stream<List<Activity>> watchRecent(String householdId, {int limit = 5});
  Stream<List<Activity>> watchMonth(String householdId, DateTime month);
}
