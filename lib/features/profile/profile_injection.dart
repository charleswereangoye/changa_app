import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';

import 'data/datasources/user_remote_datasource.dart';
import 'data/repositories/user_repository_impl.dart';
import 'domain/repositories/user_repository.dart';
import 'domain/usecases/get_users_by_ids.dart';
import 'domain/usecases/update_profile.dart';
import 'domain/usecases/watch_user.dart';
import 'presentation/cubit/profile_cubit.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'data/services/shared_preferences_service.dart';
import 'domain/services/preferences_service.dart';

final sl = GetIt.instance;

Future<void> initProfile() async {
  if (!sl.isRegistered<PreferencesService>()) {
    final preferences = await SharedPreferences.getInstance();

    sl.registerSingleton<PreferencesService>(
      SharedPreferencesService(preferences),
    );
  }

  // Remote data source
  if (!sl.isRegistered<UserRemoteDataSource>()) {
    sl.registerLazySingleton<UserRemoteDataSource>(
      () => UserRemoteDataSourceImpl(
        firestore: sl.isRegistered<FirebaseFirestore>()
            ? sl<FirebaseFirestore>()
            : FirebaseFirestore.instance,
      ),
    );
  }

  // Repository
  if (!sl.isRegistered<UserRepository>()) {
    sl.registerLazySingleton<UserRepository>(
      () => UserRepositoryImpl(
        remoteDataSource: sl<UserRemoteDataSource>(),
        firebaseAuth: sl.isRegistered<FirebaseAuth>()
            ? sl<FirebaseAuth>()
            : FirebaseAuth.instance,
      ),
    );
  }

  // Use cases
  if (!sl.isRegistered<GetUsersByIds>()) {
    sl.registerLazySingleton(() => GetUsersByIds(sl<UserRepository>()));
  }
  if (!sl.isRegistered<WatchUser>()) {
    sl.registerLazySingleton(() => WatchUser(sl<UserRepository>()));
  }
  if (!sl.isRegistered<UpdateProfile>()) {
    sl.registerLazySingleton(() => UpdateProfile(sl<UserRepository>()));
  }

  // Cubit
  if (!sl.isRegistered<ProfileCubit>()) {
    sl.registerFactory(
      () => ProfileCubit(
        watchUser: sl<WatchUser>(),
        updateProfile: sl<UpdateProfile>(),
      ),
    );
  }
}
