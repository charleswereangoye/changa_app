// Owner: A - Person A (Foundation, Authentication, Profile)
// Description: UseCase: Stream user authentication state changes

import '../../../../core/usecase/usecase.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

class WatchAuthState implements StreamUseCase<AppUser?, NoParams> {
  final AuthRepository repository;

  const WatchAuthState(this.repository);

  @override
  Stream<AppUser?> call(NoParams params) {
    return repository.authStateChanges;
  }
}
