import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../domain/entities/app_user.dart';

/// Data model representing a user, with JSON/Firestore serialization.
class UserModel extends AppUser {
  const UserModel({
    required super.uid,
    required super.fullName,
    required super.email,
    required super.phone,
    super.householdId,
    required super.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    DateTime createdAtDate;
    final rawCreatedAt = map[UserFields.createdAt];
    if (rawCreatedAt is Timestamp) {
      createdAtDate = rawCreatedAt.toDate();
    } else if (rawCreatedAt is String) {
      createdAtDate = DateTime.tryParse(rawCreatedAt) ?? DateTime.now();
    } else {
      createdAtDate = DateTime.now();
    }

    return UserModel(
      uid: uid,
      fullName: map[UserFields.fullName] as String? ?? '',
      email: map[UserFields.email] as String? ?? '',
      phone: map[UserFields.phone] as String? ?? '',
      householdId: map[UserFields.householdId] as String?,
      createdAt: createdAtDate,
    );
  }

  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      UserFields.fullName: fullName,
      UserFields.email: email,
      UserFields.phone: phone,
      UserFields.householdId: householdId,
      UserFields.createdAt: Timestamp.fromDate(createdAt),
    };
  }
}
