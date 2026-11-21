// Owner: A - Person A (Foundation, Authentication, Profile)
// Description: UseCase: Authenticate existing user with email and password

import '../../../../core/error/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

class SignInWithEmailParams {
  final String email;
  final String password;

  const SignInWithEmailParams({required this.email, required this.password});
}

class SignInWithEmail implements UseCase<AppUser, SignInWithEmailParams> {
  final AuthRepository repository;

  const SignInWithEmail(this.repository);

  @override
  Future<Result<AppUser>> call(SignInWithEmailParams params) {
    return repository.loginWithEmail(
      email: params.email,
      password: params.password,
    );
  }
}
