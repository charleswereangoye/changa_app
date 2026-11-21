import 'package:get_it/get_it.dart';

import 'data/datasources/auth_remote_datasource.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/usecases/check_email_verified.dart';
import 'domain/usecases/send_email_verification.dart';
import 'domain/usecases/send_password_reset.dart';
import 'domain/usecases/sign_in_with_email.dart';
import 'domain/usecases/sign_in_with_google.dart';
import 'domain/usecases/sign_out.dart';
import 'domain/usecases/sign_up_with_email.dart';
import 'domain/usecases/watch_auth_state.dart';
import 'presentation/cubit/auth_cubit.dart';
import 'presentation/cubit/forgot_password_cubit.dart';
import 'presentation/cubit/login_cubit.dart';
import 'presentation/cubit/sign_up_cubit.dart';
import 'presentation/cubit/verify_email_cubit.dart';

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

  // Use cases
  if (!sl.isRegistered<SignUpWithEmail>()) {
    sl.registerLazySingleton<SignUpWithEmail>(() => SignUpWithEmail(sl()));
  }
  if (!sl.isRegistered<SignInWithEmail>()) {
    sl.registerLazySingleton<SignInWithEmail>(() => SignInWithEmail(sl()));
  }
  if (!sl.isRegistered<SignInWithGoogle>()) {
    sl.registerLazySingleton<SignInWithGoogle>(() => SignInWithGoogle(sl()));
  }
  if (!sl.isRegistered<SignOut>()) {
    sl.registerLazySingleton<SignOut>(() => SignOut(sl()));
  }
  if (!sl.isRegistered<SendPasswordReset>()) {
    sl.registerLazySingleton<SendPasswordReset>(() => SendPasswordReset(sl()));
  }
  if (!sl.isRegistered<SendEmailVerification>()) {
    sl.registerLazySingleton<SendEmailVerification>(
      () => SendEmailVerification(sl()),
    );
  }
  if (!sl.isRegistered<CheckEmailVerified>()) {
    sl.registerLazySingleton<CheckEmailVerified>(
      () => CheckEmailVerified(sl()),
    );
  }
  if (!sl.isRegistered<WatchAuthState>()) {
    sl.registerLazySingleton<WatchAuthState>(() => WatchAuthState(sl()));
  }

  // Cubits
  if (!sl.isRegistered<SignUpCubit>()) {
    sl.registerFactory(
      () => SignUpCubit(
        signUpWithEmail: sl(),
        signInWithGoogle: sl(),
        authRepository: sl(),
      ),
    );
  }
  if (!sl.isRegistered<LoginCubit>()) {
    sl.registerFactory(
      () => LoginCubit(
        signInWithEmail: sl(),
        signInWithGoogle: sl(),
        authRepository: sl(),
      ),
    );
  }
  if (!sl.isRegistered<ForgotPasswordCubit>()) {
    sl.registerFactory(
      () => ForgotPasswordCubit(sendPasswordReset: sl(), authRepository: sl()),
    );
  }
  if (!sl.isRegistered<VerifyEmailCubit>()) {
    sl.registerFactory(
      () => VerifyEmailCubit(
        sendEmailVerification: sl(),
        checkEmailVerified: sl(),
        authRepository: sl(),
      ),
    );
  }
  if (!sl.isRegistered<AuthCubit>()) {
    sl.registerLazySingleton<AuthCubit>(
      () => AuthCubit(authRepository: sl<AuthRepository>()),
    );
  }
}
