// Owner: A - Person A (Foundation, Authentication, Profile)
// Description: UseCase: Reload and check whether email is verified

import '../../../../core/error/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

class CheckEmailVerified implements UseCase<bool, NoParams> {
  final AuthRepository repository;

  const CheckEmailVerified(this.repository);

  @override
  Future<Result<bool>> call(NoParams params) {
    return repository.reloadAndCheckEmailVerified();
  }
}
