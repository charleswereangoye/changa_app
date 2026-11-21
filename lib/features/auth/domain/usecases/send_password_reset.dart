// Owner: A - Person A (Foundation, Authentication, Profile)
// Description: UseCase: Send password reset email

import '../../../../core/error/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

class SendPasswordReset implements UseCase<void, String> {
  final AuthRepository repository;

  const SendPasswordReset(this.repository);

  @override
  Future<Result<void>> call(String email) {
    return repository.sendPasswordReset(email);
  }
}
