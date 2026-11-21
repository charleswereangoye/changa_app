// Owner: A - Person A (Foundation, Authentication, Profile)
// Description: UseCase: Authenticate using Google Sign-In

import '../../../../core/error/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

class SignInWithGoogle implements UseCase<AppUser, NoParams> {
  final AuthRepository repository;

  const SignInWithGoogle(this.repository);

  @override
  Future<Result<AppUser>> call(NoParams params) {
    return repository.signInWithGoogle();
  }
}
