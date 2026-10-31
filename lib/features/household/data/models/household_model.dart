import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:changa_app/core/constants/firestore_paths.dart';
import 'package:changa_app/features/household/domain/entities/household.dart';

class HouseholdModel extends Household {
  const HouseholdModel({
    required super.id,
    required super.name,
    required super.type,
    required super.expectedMembers,
    required super.pin,
    required super.adminUid,
    required super.createdAt,
  });

  factory HouseholdModel.fromEntity(Household entity) {
    return HouseholdModel(
      id: entity.id,
      name: entity.name,
      type: entity.type,
      expectedMembers: entity.expectedMembers,
      pin: entity.pin,
      adminUid: entity.adminUid,
      createdAt: entity.createdAt,
    );
  }

  factory HouseholdModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
    return HouseholdModel.fromMap(doc.id, data);
  }

  factory HouseholdModel.fromMap(String id, Map<String, dynamic> map) {
    final typeString = map[HouseholdFields.type] as String?;
    final type = HouseholdType.values.firstWhere(
      (e) => e.name == typeString,
      orElse: () => HouseholdType.apartment,
    );

    final rawCreatedAt = map[HouseholdFields.createdAt];
    final DateTime createdAt;
    if (rawCreatedAt is Timestamp) {
      createdAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is DateTime) {
      createdAt = rawCreatedAt;
    } else {
      createdAt = DateTime.now();
    }

    return HouseholdModel(
      id: id,
      name: (map[HouseholdFields.name] as String?) ?? '',
      type: type,
      expectedMembers:
          (map[HouseholdFields.expectedMembers] as num?)?.toInt() ?? 2,
      pin: (map[HouseholdFields.pin] as String?) ?? '',
      adminUid: (map[HouseholdFields.adminUid] as String?) ?? '',
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap({bool useServerTimestamp = true}) {
    return {
      HouseholdFields.name: name,
      HouseholdFields.type: type.name,
      HouseholdFields.expectedMembers: expectedMembers,
      HouseholdFields.pin: pin,
      HouseholdFields.adminUid: adminUid,
      HouseholdFields.createdAt: useServerTimestamp
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt),
    };
  }

  Map<String, dynamic> toJson() => toMap(useServerTimestamp: false);

  Household toEntity() {
    return Household(
      id: id,
      name: name,
      type: type,
      expectedMembers: expectedMembers,
      pin: pin,
      adminUid: adminUid,
      createdAt: createdAt,
    );
  }
}
