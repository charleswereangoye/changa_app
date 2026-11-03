// Owner: A - Person A (Foundation, Authentication, Profile)
// Description: UserRepository domain interface

import 'dart:async';

import '../../../../core/error/result.dart';
import '../../../auth/domain/entities/app_user.dart';

abstract class UserRepository {
  Stream<AppUser?> watchUser(String uid);
  Future<Result<List<AppUser>>> getUsersByIds(List<String> uids);
  Future<Result<AppUser>> updateProfile({String? fullName, String? phone});
}
