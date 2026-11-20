// Owner: A - Person A (Foundation, Authentication, Profile)
// Description: UseCase: Sign out authenticated user

import '../../../../core/error/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

class SignOut implements UseCase<void, NoParams> {
  final AuthRepository repository;

  const SignOut(this.repository);

  @override
  Future<Result<void>> call(NoParams params) {
    return repository.signOut();
  }
}
