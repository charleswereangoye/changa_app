// Owner: A - Person A (Foundation, Authentication, Profile)
// Description: Mock classes for unit and bloc testing (Auth, Firebase, Repositories, UseCases)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mocktail/mocktail.dart';

import 'package:changa_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:changa_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:changa_app/features/auth/domain/usecases/check_email_verified.dart';
import 'package:changa_app/features/auth/domain/usecases/send_email_verification.dart';
import 'package:changa_app/features/auth/domain/usecases/send_password_reset.dart';
import 'package:changa_app/features/auth/domain/usecases/sign_in_with_email.dart';
import 'package:changa_app/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:changa_app/features/auth/domain/usecases/sign_out.dart';
import 'package:changa_app/features/auth/domain/usecases/sign_up_with_email.dart';
import 'package:changa_app/features/profile/data/datasources/user_remote_datasource.dart';
import 'package:changa_app/features/profile/domain/repositories/user_repository.dart';
import 'package:changa_app/features/profile/domain/usecases/get_users_by_ids.dart';
import 'package:changa_app/features/profile/domain/usecases/update_profile.dart';
import 'package:changa_app/features/profile/domain/usecases/watch_user.dart';

// Firebase & External
class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockFirebaseUser extends Mock implements User {}

class MockUserCredential extends Mock implements UserCredential {}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

// Data sources
class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class MockUserRemoteDataSource extends Mock implements UserRemoteDataSource {}

// Repositories
class MockAuthRepository extends Mock implements AuthRepository {}

class MockUserRepository extends Mock implements UserRepository {}

// Auth Use Cases
class MockSignInWithEmail extends Mock implements SignInWithEmail {}

class MockSignUpWithEmail extends Mock implements SignUpWithEmail {}

class MockSignInWithGoogle extends Mock implements SignInWithGoogle {}

class MockSignOut extends Mock implements SignOut {}

class MockSendPasswordReset extends Mock implements SendPasswordReset {}

class MockSendEmailVerification extends Mock implements SendEmailVerification {}

class MockCheckEmailVerified extends Mock implements CheckEmailVerified {}

// Profile Use Cases
class MockWatchUser extends Mock implements WatchUser {}

class MockUpdateProfile extends Mock implements UpdateProfile {}

class MockGetUsersByIds extends Mock implements GetUsersByIds {}
