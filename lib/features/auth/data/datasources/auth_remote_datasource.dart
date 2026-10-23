import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/firestore_paths.dart';
import '../models/user_model.dart';


abstract class AuthRemoteDataSource {
  Stream<User?> get authStateChanges;
  User? get currentFirebaseUser;

  Future<UserModel> signUpWithEmail({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  });

  Future<UserModel> loginWithEmail({
    required String email,
    required String password,
  });

  Future<UserModel> signInWithGoogle();
  Future<UserModel> signInWithApple();
  Future<void> signOut();
  Future<void> sendPasswordReset(String email);
  Future<UserModel?> getUserProfile(String uid);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRemoteDataSourceImpl({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  User? get currentFirebaseUser => _auth.currentUser;

  @override
  Future<UserModel> signUpWithEmail({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-null',
        message: 'Failed to create user account.',
      );
    }

    await user.updateDisplayName(fullName.trim());

    final userModel = UserModel(
      uid: user.uid,
      fullName: fullName.trim(),
      email: email.trim(),
      phone: phone.trim(),
      createdAt: DateTime.now(),
    );

    await _firestore.doc(FirestorePaths.user(user.uid)).set(userModel.toMap());

    return userModel;
  }

  @override
  Future<UserModel> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-null',
        message: 'Failed to sign in.',
      );
    }

    final profile = await getUserProfile(user.uid);
    if (profile != null) {
      return profile;
    }

    final fallbackModel = UserModel(
      uid: user.uid,
      fullName: user.displayName ?? '',
      email: user.email ?? email,
      phone: user.phoneNumber ?? '',
      createdAt: DateTime.now(),
    );
    await _firestore
        .doc(FirestorePaths.user(user.uid))
        .set(fallbackModel.toMap());
    return fallbackModel;
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await GoogleSignIn.instance.initialize(
        serverClientId: AppConstants.googleServerClientId,
      );
    }
    final googleUser = await GoogleSignIn.instance.authenticate();


    final googleAuth = googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    final authResult = await _auth.signInWithCredential(credential);
    final user = authResult.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-null',
        message: 'Failed to authenticate with Google.',
      );
    }

    final existing = await getUserProfile(user.uid);
    if (existing != null) {
      return existing;
    }

    final newUser = UserModel(
      uid: user.uid,
      fullName: user.displayName ?? googleUser.displayName ?? '',
      email: user.email ?? googleUser.email,
      phone: user.phoneNumber ?? '',
      createdAt: DateTime.now(),
    );

    await _firestore.doc(FirestorePaths.user(user.uid)).set(newUser.toMap());
    return newUser;
  }

  @override
  Future<UserModel> signInWithApple() async {
    final provider = OAuthProvider('apple.com');
    final authResult = await _auth.signInWithProvider(provider);
    final user = authResult.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-null',
        message: 'Failed to authenticate with Apple.',
      );
    }

    final existing = await getUserProfile(user.uid);
    if (existing != null) {
      return existing;
    }

    final newUser = UserModel(
      uid: user.uid,
      fullName: user.displayName ?? '',
      email: user.email ?? '',
      phone: user.phoneNumber ?? '',
      createdAt: DateTime.now(),
    );
    await _firestore.doc(FirestorePaths.user(user.uid)).set(newUser.toMap());
    return newUser;
  }

  @override
  Future<void> signOut() async {
    await Future.wait([_auth.signOut(), GoogleSignIn.instance.signOut()]);
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  @override
  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _firestore.doc(FirestorePaths.user(uid)).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromDocument(doc);
    }
    return null;
  }
}
