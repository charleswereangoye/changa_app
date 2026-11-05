import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';

import '../../core/services/local_notification_service.dart';
import 'data/datasources/notification_remote_datasource.dart';
import 'data/repositories/notification_repository_impl.dart';
import 'domain/repositories/notification_repository.dart';
import 'domain/usecases/mark_all_read.dart';
import 'domain/usecases/mark_notification_read.dart';
import 'domain/usecases/watch_unread_notifications.dart';
import 'presentation/cubit/notifications_cubit.dart';

final sl = GetIt.instance;

Future<void> initNotifications() async {
  if (!sl.isRegistered<FirebaseFirestore>()) {
    sl.registerLazySingleton<FirebaseFirestore>(
      () => FirebaseFirestore.instance,
    );
  }

  if (!sl.isRegistered<FirebaseAuth>()) {
    sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  }

  if (!sl.isRegistered<FlutterLocalNotificationsPlugin>()) {
    sl.registerLazySingleton<FlutterLocalNotificationsPlugin>(
      () => FlutterLocalNotificationsPlugin(),
    );
  }

  if (!sl.isRegistered<LocalNotificationService>()) {
    sl.registerLazySingleton<LocalNotificationService>(
      () => LocalNotificationService(sl<FlutterLocalNotificationsPlugin>()),
    );
  }

  sl.registerLazySingleton<NotificationRemoteDataSource>(
    () => NotificationRemoteDataSource(sl<FirebaseFirestore>()),
  );

  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(
      sl<NotificationRemoteDataSource>(),
      sl<FirebaseAuth>(),
    ),
  );

  sl.registerLazySingleton<WatchUnreadNotifications>(
    () => WatchUnreadNotifications(sl<NotificationRepository>()),
  );

  sl.registerLazySingleton<MarkNotificationRead>(
    () => MarkNotificationRead(sl<NotificationRepository>()),
  );

  sl.registerLazySingleton<MarkAllRead>(
    () => MarkAllRead(sl<NotificationRepository>()),
  );

  sl.registerFactory<NotificationsCubit>(
    () => NotificationsCubit(
      sl<WatchUnreadNotifications>(),
      sl<MarkNotificationRead>(),
      sl<MarkAllRead>(),
    ),
  );
}
