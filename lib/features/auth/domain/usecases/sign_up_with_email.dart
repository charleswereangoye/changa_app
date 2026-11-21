// Owner: A - Person A (Foundation, Authentication, Profile)
// Description: UseCase: Register new user with email and password

import '../../../../core/error/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

class SignUpWithEmailParams {
  final String fullName;
  final String email;
  final String phone;
  final String password;

  const SignUpWithEmailParams({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.password,
  });
}

class SignUpWithEmail implements UseCase<AppUser, SignUpWithEmailParams> {
  final AuthRepository repository;

  const SignUpWithEmail(this.repository);

  @override
  Future<Result<AppUser>> call(SignUpWithEmailParams params) {
    return repository.signUpWithEmail(
      fullName: params.fullName,
      email: params.email,
      phone: params.phone,
      password: params.password,
    );
  }
}
