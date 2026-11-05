// Owner: A - Person A (Foundation, Authentication, Profile)
// Description: UserRepository implementation

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/user_remote_datasource.dart';

class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource remoteDataSource;
  final FirebaseAuth? firebaseAuth;
  final String? Function()? currentUidResolver;

  UserRepositoryImpl({
    required this.remoteDataSource,
    this.firebaseAuth,
    this.currentUidResolver,
  });

  String _requireCurrentUid() {
    if (currentUidResolver != null) {
      final uid = currentUidResolver!();
      if (uid != null && uid.isNotEmpty) return uid;
    }
    try {
      final uid = (firebaseAuth ?? FirebaseAuth.instance).currentUser?.uid;
      if (uid != null && uid.isNotEmpty) return uid;
    } catch (_) {}
    throw const AuthFailure('You must be signed in to perform this action.');
  }

  Failure _mapException(Object error) {
    if (error is Failure) return error;
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return const PermissionFailure();
        case 'not-found':
          return const NotFoundFailure();
        case 'unavailable':
        case 'network-request-failed':
          return const NetworkFailure();
        default:
          return UnknownFailure(
            error.message ?? 'A database error occurred. Please try again.',
          );
      }
    }
    return UnknownFailure(error.toString());
  }

  @override
  Stream<AppUser?> watchUser(String uid) {
    return remoteDataSource.watchUser(uid).map((model) => model);
  }

  @override
  Future<Result<List<AppUser>>> getUsersByIds(List<String> uids) async {
    try {
      final users = await remoteDataSource.getUsersByIds(uids);
      return Result.success(users);
    } catch (e) {
      return Result.failure(_mapException(e));
    }
  }

  @override
  Future<Result<AppUser>> updateProfile({
    String? fullName,
    String? phone,
  }) async {
    try {
      final uid = _requireCurrentUid();
      final updated = await remoteDataSource.updateProfile(
        uid: uid,
        fullName: fullName,
        phone: phone,
      );
      return Result.success(updated);
    } catch (e) {
      return Result.failure(_mapException(e));
    }
  }
}
