import 'package:equatable/equatable.dart';

/// Domain entity representing an authenticated Changa user.
class AppUser extends Equatable {
  final String uid;
  final String fullName;
  final String email;
  final String phone;
  final String? householdId;
  final DateTime createdAt;

  const AppUser({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phone,
    this.householdId,
    required this.createdAt,
  });

  AppUser copyWith({
    String? uid,
    String? fullName,
    String? email,
    String? phone,
    String? householdId,
    DateTime? createdAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      householdId: householdId ?? this.householdId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    uid,
    fullName,
    email,
    phone,
    householdId,
    createdAt,
  ];
}
