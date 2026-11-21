// Owner: A - Person A (Foundation, Authentication, Profile)
// Description: UseCase: Send verification email to currently signed in user

import '../../../../core/error/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

class SendEmailVerification implements UseCase<void, NoParams> {
  final AuthRepository repository;

  const SendEmailVerification(this.repository);

  @override
  Future<Result<void>> call(NoParams params) {
    return repository.sendEmailVerification();
  }
}
