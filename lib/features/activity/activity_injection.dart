// Dependency injection registration for Activity feature

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:changa_app/features/activity/data/activity_writer.dart';
import 'package:changa_app/features/activity/data/datasources/activity_remote_datasource.dart';
import 'package:changa_app/features/activity/data/repositories/activity_repository_impl.dart';
import 'package:changa_app/features/activity/domain/repositories/activity_repository.dart';
import 'package:changa_app/features/activity/domain/usecases/watch_month_activity.dart';
import 'package:changa_app/features/activity/domain/usecases/watch_recent_activity.dart';
import 'package:changa_app/features/activity/presentation/cubit/activity_cubit.dart';

final sl = GetIt.instance;

Future<void> initActivity() async {
  if (!sl.isRegistered<ActivityWriter>()) {
    sl.registerLazySingleton<ActivityWriter>(
      () => ActivityWriter(
        firestore: sl.isRegistered<FirebaseFirestore>()
            ? sl<FirebaseFirestore>()
            : null,
      ),
    );
  }

  if (!sl.isRegistered<ActivityRemoteDataSource>()) {
    sl.registerLazySingleton<ActivityRemoteDataSource>(
      () => ActivityRemoteDataSourceImpl(
        firestore: sl.isRegistered<FirebaseFirestore>()
            ? sl<FirebaseFirestore>()
            : null,
      ),
    );
  }

  if (!sl.isRegistered<ActivityRepository>()) {
    sl.registerLazySingleton<ActivityRepository>(
      () => ActivityRepositoryImpl(
        remoteDataSource: sl<ActivityRemoteDataSource>(),
      ),
    );
  }

  if (!sl.isRegistered<WatchRecentActivity>()) {
    sl.registerLazySingleton<WatchRecentActivity>(
      () => WatchRecentActivity(sl<ActivityRepository>()),
    );
  }

  if (!sl.isRegistered<WatchMonthActivity>()) {
    sl.registerLazySingleton<WatchMonthActivity>(
      () => WatchMonthActivity(sl<ActivityRepository>()),
    );
  }

  if (!sl.isRegistered<ActivityCubit>()) {
    sl.registerFactory<ActivityCubit>(
      () => ActivityCubit(
        watchMonthActivity: sl<WatchMonthActivity>(),
        watchRecentActivity: sl<WatchRecentActivity>(),
      ),
    );
  }
}
