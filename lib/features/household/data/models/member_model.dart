import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:changa_app/core/constants/firestore_paths.dart';
import 'package:changa_app/features/household/domain/entities/member.dart';

class MemberModel extends Member {
  const MemberModel({
    required super.uid,
    required super.role,
    required super.credits,
    required super.joinedAt,
  });

  factory MemberModel.fromEntity(Member entity) {
    return MemberModel(
      uid: entity.uid,
      role: entity.role,
      credits: entity.credits,
      joinedAt: entity.joinedAt,
    );
  }

  factory MemberModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
    return MemberModel.fromMap(doc.id, data);
  }

  factory MemberModel.fromMap(String uid, Map<String, dynamic> map) {
    final roleString = map[MemberFields.role] as String?;
    final role = MemberRole.values.firstWhere(
      (e) => e.name == roleString,
      orElse: () => MemberRole.member,
    );

    final rawJoinedAt = map[MemberFields.joinedAt];
    final DateTime joinedAt;
    if (rawJoinedAt is Timestamp) {
      joinedAt = rawJoinedAt.toDate();
    } else if (rawJoinedAt is DateTime) {
      joinedAt = rawJoinedAt;
    } else {
      joinedAt = DateTime.now();
    }

    return MemberModel(
      uid: uid,
      role: role,
      credits: (map[MemberFields.credits] as num?)?.toInt() ?? 0,
      joinedAt: joinedAt,
    );
  }

  Map<String, dynamic> toMap({bool useServerTimestamp = true}) {
    return {
      MemberFields.role: role.name,
      MemberFields.credits: credits,
      MemberFields.joinedAt: useServerTimestamp
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(joinedAt),
    };
  }

  Map<String, dynamic> toJson() => toMap(useServerTimestamp: false);

  Member toEntity() {
    return Member(uid: uid, role: role, credits: credits, joinedAt: joinedAt);
  }
}
