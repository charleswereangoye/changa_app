import '../../../../core/error/result.dart';
import '../entities/app_user.dart';

/// Contract for authentication operations.
abstract class AuthRepository {
  /// Stream of user authentication state changes.
  Stream<AppUser?> get authStateChanges;

  /// Currently signed in user, if any.
  AppUser? get currentUser;

  /// Registers a new user with email and password.
  Future<Result<AppUser>> signUpWithEmail({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  });

  /// Authenticates an existing user with email and password.
  Future<Result<AppUser>> loginWithEmail({
    required String email,
    required String password,
  });

  /// Authenticates using Google Sign-In.
  Future<Result<AppUser>> signInWithGoogle();

  /// Authenticates using Apple Sign-In.
  Future<Result<AppUser>> signInWithApple();

  /// Signs out the current user.
  Future<Result<void>> signOut();

  /// Sends a password reset email.
  Future<Result<void>> sendPasswordReset(String email);
}
