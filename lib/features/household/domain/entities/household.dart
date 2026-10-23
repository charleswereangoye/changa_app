import 'package:equatable/equatable.dart';

enum HouseholdType { apartment, dorm, house }

class Household extends Equatable {
  final String id;
  final String name;
  final HouseholdType type;
  final int expectedMembers;
  final String pin;
  final String adminUid;
  final DateTime createdAt;

  const Household({
    required this.id,
    required this.name,
    required this.type,
    required this.expectedMembers,
    required this.pin,
    required this.adminUid,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, name, type, expectedMembers, pin, adminUid, createdAt];
}