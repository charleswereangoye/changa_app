import 'package:get_it/get_it.dart';

import 'data/datasources/auth_remote_datasource.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'domain/repositories/auth_repository.dart';
import 'presentation/cubit/login_cubit.dart';
import 'presentation/cubit/sign_up_cubit.dart';

final sl = GetIt.instance;

Future<void> initAuth() async {
  // Remote data source
  if (!sl.isRegistered<AuthRemoteDataSource>()) {
    sl.registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(),
    );
  }

  // Repository
  if (!sl.isRegistered<AuthRepository>()) {
    sl.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(remoteDataSource: sl()),
    );
  }

  // Cubits
  if (!sl.isRegistered<SignUpCubit>()) {
    sl.registerFactory(() => SignUpCubit(authRepository: sl()));
  }
  if (!sl.isRegistered<LoginCubit>()) {
    sl.registerFactory(() => LoginCubit(authRepository: sl()));
  }
}
