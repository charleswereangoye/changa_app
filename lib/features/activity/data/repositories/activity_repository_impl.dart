// ActivityRepository implementation

import 'package:changa_app/features/activity/data/datasources/activity_remote_datasource.dart';
import 'package:changa_app/features/activity/domain/entities/activity.dart';
import 'package:changa_app/features/activity/domain/repositories/activity_repository.dart';

class ActivityRepositoryImpl implements ActivityRepository {
  final ActivityRemoteDataSource remoteDataSource;

  const ActivityRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<List<Activity>> watchRecent(String householdId, {int limit = 5}) {
    return remoteDataSource.watchRecent(householdId, limit: limit);
  }

  @override
  Stream<List<Activity>> watchMonth(String householdId, DateTime month) {
    return remoteDataSource.watchMonth(householdId, month);
  }
}
