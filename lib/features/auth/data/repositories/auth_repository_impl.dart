import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  AppUser? _cachedUser;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<AppUser?> get authStateChanges {
    return remoteDataSource.authStateChanges.asyncMap((firebaseUser) async {
      if (firebaseUser == null) {
        _cachedUser = null;
        return null;
      }
      final profile = await remoteDataSource.getUserProfile(firebaseUser.uid);
      _cachedUser = profile;
      return profile;
    });
  }

  @override
  AppUser? get currentUser => _cachedUser;

  @override
  Future<Result<AppUser>> signUpWithEmail({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final user = await remoteDataSource.signUpWithEmail(
        fullName: fullName,
        email: email,
        phone: phone,
        password: password,
      );
      _cachedUser = user;
      return Result.success(user);
    } on FirebaseAuthException catch (e) {
      return Result.failure(_mapFirebaseAuthException(e));
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return Result.failure(
          const PermissionFailure(
            'Firestore database permission denied. Check your Firestore rules in Firebase Console.',
          ),
        );
      }
      return Result.failure(UnknownFailure(e.message ?? e.toString()));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<AppUser>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final user = await remoteDataSource.loginWithEmail(
        email: email,
        password: password,
      );
      _cachedUser = user;
      return Result.success(user);
    } on FirebaseAuthException catch (e) {
      return Result.failure(_mapFirebaseAuthException(e));
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return Result.failure(
          const PermissionFailure(
            'Firestore database permission denied. Check your Firestore rules in Firebase Console.',
          ),
        );
      }
      return Result.failure(UnknownFailure(e.message ?? e.toString()));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<AppUser>> signInWithGoogle() async {
    try {
      final user = await remoteDataSource.signInWithGoogle();
      _cachedUser = user;
      return Result.success(user);
    } on FirebaseAuthException catch (e) {
      return Result.failure(_mapFirebaseAuthException(e));
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return Result.failure(
          const AuthFailure('Google sign-in was cancelled.'),
        );
      }
      return Result.failure(
        AuthFailure(e.description ?? 'Google sign-in failed.'),
      );
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return Result.failure(
          const PermissionFailure(
            'Firestore database permission denied. Check your Firestore rules in Firebase Console.',
          ),
        );
      }
      return Result.failure(UnknownFailure(e.message ?? e.toString()));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<AppUser>> signInWithApple() async {
    try {
      final user = await remoteDataSource.signInWithApple();
      _cachedUser = user;
      return Result.success(user);
    } on FirebaseAuthException catch (e) {
      return Result.failure(_mapFirebaseAuthException(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await remoteDataSource.signOut();
      _cachedUser = null;
      return Result.success(null);
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> sendPasswordReset(String email) async {
    try {
      await remoteDataSource.sendPasswordReset(email);
      return Result.success(null);
    } on FirebaseAuthException catch (e) {
      return Result.failure(_mapFirebaseAuthException(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  Failure _mapFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return const AuthFailure('No account found with this email.');
      case 'wrong-password':
      case 'invalid-credential':
        return const AuthFailure('Invalid email or password.');
      case 'email-already-in-use':
        return const AuthFailure('An account already exists for this email.');
      case 'weak-password':
        return const AuthFailure('Password is too weak.');
      case 'invalid-email':
        return const AuthFailure('Please enter a valid email address.');
      case 'network-request-failed':
        return const NetworkFailure();
      case 'configuration-not-found':
        return const AuthFailure(
          'Email/Password sign-in is disabled in Firebase Console. Please enable it under Authentication > Sign-in method.',
        );
      default:
        return AuthFailure(e.message ?? 'Authentication failed.');
    }
  }
}
