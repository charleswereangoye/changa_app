// Owner: A - Person A (Foundation, Authentication, Profile)
// Description: UseCase: Update current user's profile fields

import '../../../../core/error/result.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../repositories/user_repository.dart';

class UpdateProfile {
  final UserRepository repository;

  const UpdateProfile(this.repository);

  Future<Result<AppUser>> call({String? fullName, String? phone}) {
    return repository.updateProfile(fullName: fullName, phone: phone);
  }
}
