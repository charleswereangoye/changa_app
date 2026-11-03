// Owner: A - Person A (Foundation, Authentication, Profile)
// Description: UseCase: Watch a single user's profile stream

import '../../../auth/domain/entities/app_user.dart';
import '../repositories/user_repository.dart';

class WatchUser {
  final UserRepository repository;

  const WatchUser(this.repository);

  Stream<AppUser?> call(String uid) {
    return repository.watchUser(uid);
  }
}
