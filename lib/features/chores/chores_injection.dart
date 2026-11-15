import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';

import 'package:changa_app/features/activity/data/activity_writer.dart';
import 'package:changa_app/features/chores/data/datasources/chore_remote_datasource.dart';
import 'package:changa_app/features/chores/data/datasources/swap_remote_datasource.dart';
import 'package:changa_app/features/chores/data/repositories/chore_repository_impl.dart';
import 'package:changa_app/features/chores/domain/repositories/chore_repository.dart';
import 'package:changa_app/features/chores/domain/usecases/cancel_swap.dart';
import 'package:changa_app/features/chores/domain/usecases/complete_chore.dart';
import 'package:changa_app/features/chores/domain/usecases/create_chore.dart';
import 'package:changa_app/features/chores/domain/usecases/delete_chore.dart';
import 'package:changa_app/features/chores/domain/usecases/reassign_chores.dart';
import 'package:changa_app/features/chores/domain/usecases/request_swap.dart';
import 'package:changa_app/features/chores/domain/usecases/respond_to_swap.dart';
import 'package:changa_app/features/chores/domain/usecases/update_chore.dart';
import 'package:changa_app/features/chores/domain/usecases/watch_all_chores.dart';
import 'package:changa_app/features/chores/domain/usecases/watch_chores_for_day.dart';
import 'package:changa_app/features/chores/domain/usecases/watch_swap_requests.dart';
import 'package:changa_app/features/notifications/data/notification_writer.dart';

/// Called from injection_container.dart. Cubits get added here with E9 to E12.
Future<void> initChores() async {
  final sl = GetIt.I;

  // Shared pieces other features may also register. Guarded so whoever
  // gets there first wins and nothing is registered twice.
  if (!sl.isRegistered<FirebaseFirestore>()) {
    sl.registerLazySingleton<FirebaseFirestore>(
      () => FirebaseFirestore.instance,
    );
  }
  if (!sl.isRegistered<FirebaseAuth>()) {
    sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  }
  if (!sl.isRegistered<ActivityWriter>()) {
    sl.registerLazySingleton(
      () => ActivityWriter(firestore: sl<FirebaseFirestore>()),
    );
  }
  if (!sl.isRegistered<NotificationWriter>()) {
    sl.registerLazySingleton(() => NotificationWriter(sl<FirebaseFirestore>()));
  }

  sl
    ..registerLazySingleton(() => ChoreRemoteDataSource(sl(), sl(), sl()))
    ..registerLazySingleton(() => SwapRemoteDataSource(sl(), sl(), sl(), sl()))
    ..registerLazySingleton<ChoreRepository>(
      () => ChoreRepositoryImpl(sl(), sl()),
    )
    ..registerLazySingleton(() => WatchChoresForDay(sl()))
    ..registerLazySingleton(() => WatchAllChores(sl()))
    ..registerLazySingleton(() => CreateChore(sl()))
    ..registerLazySingleton(() => UpdateChore(sl()))
    ..registerLazySingleton(() => DeleteChore(sl()))
    ..registerLazySingleton(() => CompleteChore(sl()))
    ..registerLazySingleton(() => ReassignChores(sl()))
    ..registerLazySingleton(() => RequestSwap(sl()))
    ..registerLazySingleton(() => RespondToSwap(sl()))
    ..registerLazySingleton(() => CancelSwap(sl()))
    ..registerLazySingleton(() => WatchSwapRequests(sl()));
}
