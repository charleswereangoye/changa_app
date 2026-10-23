import 'package:equatable/equatable.dart';

enum MemberRole { admin, member }

class Member extends Equatable {
  final String uid;
  final MemberRole role;
  final int credits;
  final DateTime joinedAt;

  const Member({
    required this.uid,
    required this.role,
    required this.credits,
    required this.joinedAt,
  });

  @override
  List<Object?> get props => [uid, role, credits, joinedAt];
}