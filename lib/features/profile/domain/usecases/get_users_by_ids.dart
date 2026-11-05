// Owner: A - Person A (Foundation, Authentication, Profile)
// Description: UseCase: Fetch multiple users by IDs for names/avatars

import '../../../../core/error/result.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../repositories/user_repository.dart';

class GetUsersByIds {
  final UserRepository repository;

  const GetUsersByIds(this.repository);

  Future<Result<List<AppUser>>> call(List<String> uids) {
    return repository.getUsersByIds(uids);
  }
}
