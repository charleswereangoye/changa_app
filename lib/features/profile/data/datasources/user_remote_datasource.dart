// Owner: A - Person A (Foundation, Authentication, Profile)
// Description: Remote data source for User profile document operations

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../auth/data/models/user_model.dart';

abstract class UserRemoteDataSource {
  Stream<UserModel?> watchUser(String uid);
  Future<List<UserModel>> getUsersByIds(List<String> uids);
  Future<UserModel> updateProfile({
    required String uid,
    String? fullName,
    String? phone,
  });
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final FirebaseFirestore _firestore;

  UserRemoteDataSourceImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<UserModel?> watchUser(String uid) {
    if (uid.isEmpty) return Stream.value(null);
    return _firestore.doc(FirestorePaths.user(uid)).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return UserModel.fromDocument(snapshot);
    });
  }

  @override
  Future<List<UserModel>> getUsersByIds(List<String> uids) async {
    final distinctUids = uids
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    if (distinctUids.isEmpty) return [];

    final snapshots = await Future.wait(
      distinctUids.map((id) => _firestore.doc(FirestorePaths.user(id)).get()),
    );

    final users = <UserModel>[];
    for (var i = 0; i < snapshots.length; i++) {
      final snap = snapshots[i];
      final uid = distinctUids[i];
      if (snap.exists && snap.data() != null) {
        users.add(UserModel.fromDocument(snap));
      } else {
        // Fallback for removed or missing user per Section 3.1:
        // "A removed or unknown user is shown as 'Former member'. Never crash on a missing name."
        users.add(
          UserModel(
            uid: uid,
            fullName: 'Former member',
            email: '',
            phone: '',
            createdAt: DateTime.now(),
          ),
        );
      }
    }
    return users;
  }

  @override
  Future<UserModel> updateProfile({
    required String uid,
    String? fullName,
    String? phone,
  }) async {
    final docRef = _firestore.doc(FirestorePaths.user(uid));
    final updates = <String, dynamic>{};
    if (fullName != null) {
      updates[UserFields.fullName] = fullName.trim();
    }
    if (phone != null) {
      updates[UserFields.phone] = phone.trim();
    }

    if (updates.isNotEmpty) {
      await docRef.update(updates);
    }

    final snap = await docRef.get();
    if (!snap.exists || snap.data() == null) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'not-found',
        message: 'User profile not found for uid: $uid',
      );
    }
    return UserModel.fromDocument(snap);
  }
}
