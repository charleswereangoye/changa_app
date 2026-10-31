import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:changa_app/core/constants/firestore_paths.dart';
import 'package:changa_app/core/error/failures.dart';
import 'package:changa_app/core/utils/pin_generator.dart';
import 'package:changa_app/features/activity/data/activity_writer.dart';
import 'package:changa_app/features/activity/domain/entities/activity.dart';
import 'package:changa_app/features/household/data/models/household_model.dart';
import 'package:changa_app/features/household/data/models/member_model.dart';
import 'package:changa_app/features/household/domain/entities/household.dart';
import 'package:changa_app/features/household/domain/entities/household_preview.dart';
import 'package:changa_app/features/household/domain/entities/member.dart';

abstract class HouseholdRemoteDataSource {
  Stream<HouseholdModel?> watchHousehold(String householdId);

  Stream<List<MemberModel>> watchMembers(String householdId);

  Future<HouseholdModel> createHousehold({
    required String uid,
    required String name,
    required HouseholdType type,
    required int expectedMembers,
  });

  Future<HouseholdPreview> previewHouseholdByPin(String pin);

  Future<HouseholdModel> joinHousehold({
    required String uid,
    required String pin,
  });

  Future<String> regeneratePin(String householdId);

  Future<void> removeMember({
    required String householdId,
    required String callerUid,
    required String targetUid,
  });

  Future<void> transferAdmin({
    required String householdId,
    required String callerUid,
    required String newAdminUid,
  });

  Future<void> leaveHousehold({
    required String householdId,
    required String uid,
  });

  Future<bool> checkAndClearStaleHousehold({
    required String householdId,
    required String uid,
  });
}

class HouseholdRemoteDataSourceImpl implements HouseholdRemoteDataSource {
  static const int _maxPinRetries = 5;
  static const int _maxHouseholdMembers = 10;

  final FirebaseFirestore _firestore;
  final ActivityWriter _activityWriter;
  final String Function() _pinGenerator;

  HouseholdRemoteDataSourceImpl({
    FirebaseFirestore? firestore,
    ActivityWriter? activityWriter,
    String Function()? pinGenerator,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _activityWriter = activityWriter ?? ActivityWriter(firestore: firestore),
       _pinGenerator = pinGenerator ?? PinGenerator.generate;

  Future<String> _generateUniquePin({String? excludePin}) async {
    for (var attempt = 0; attempt < _maxPinRetries; attempt++) {
      final candidate = _pinGenerator();
      if (excludePin != null && candidate == excludePin) {
        continue;
      }
      final pinDoc = await _firestore
          .doc(FirestorePaths.householdPin(candidate))
          .get();
      if (!pinDoc.exists) {
        return candidate;
      }
    }
    throw const UnknownFailure(
      'Could not generate a unique household PIN. Please try again.',
    );
  }

  @override
  Stream<HouseholdModel?> watchHousehold(String householdId) {
    return _firestore
        .doc(FirestorePaths.household(householdId))
        .snapshots()
        .map((doc) => doc.exists ? HouseholdModel.fromFirestore(doc) : null);
  }

  @override
  Stream<List<MemberModel>> watchMembers(String householdId) {
    return _firestore
        .collection(FirestorePaths.members(householdId))
        .orderBy(MemberFields.joinedAt)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(MemberModel.fromFirestore).toList(),
        );
  }

  @override
  Future<HouseholdModel> createHousehold({
    required String uid,
    required String name,
    required HouseholdType type,
    required int expectedMembers,
  }) async {
    final pin = await _generateUniquePin();
    final householdRef = _firestore.collection(FirestorePaths.households).doc();
    final pinRef = _firestore.doc(FirestorePaths.householdPin(pin));
    final memberRef = _firestore.doc(
      FirestorePaths.member(householdRef.id, uid),
    );
    final userRef = _firestore.doc(FirestorePaths.user(uid));

    final now = DateTime.now();
    final householdModel = HouseholdModel(
      id: householdRef.id,
      name: name.trim(),
      type: type,
      expectedMembers: expectedMembers,
      pin: pin,
      adminUid: uid,
      createdAt: now,
    );

    final adminMember = MemberModel(
      uid: uid,
      role: MemberRole.admin,
      credits: 0,
      joinedAt: now,
    );

    final batch = _firestore.batch();
    batch.set(householdRef, householdModel.toMap());
    batch.set(pinRef, {
      PinFields.householdId: householdRef.id,
      PinFields.createdAt: FieldValue.serverTimestamp(),
    });
    batch.set(memberRef, adminMember.toMap());
    batch.set(userRef, {
      UserFields.householdId: householdRef.id,
    }, SetOptions(merge: true));

    await batch.commit();
    return householdModel;
  }

  @override
  Future<HouseholdPreview> previewHouseholdByPin(String pin) async {
    final cleanPin = pin.trim();
    final pinDoc = await _firestore
        .doc(FirestorePaths.householdPin(cleanPin))
        .get();

    if (!pinDoc.exists) {
      throw const NotFoundFailure(
        'No household found with that PIN. Please check the digits.',
      );
    }

    final householdId = pinDoc.data()?[PinFields.householdId] as String? ?? '';
    if (householdId.isEmpty) {
      throw const NotFoundFailure('Household data could not be found.');
    }

    final householdDoc = await _firestore
        .doc(FirestorePaths.household(householdId))
        .get();
    if (!householdDoc.exists) {
      throw const NotFoundFailure('Household no longer exists.');
    }

    final membersSnap = await _firestore
        .collection(FirestorePaths.members(householdId))
        .get();

    final name = (householdDoc.data()?[HouseholdFields.name] as String?) ?? '';
    return HouseholdPreview(name: name, memberCount: membersSnap.docs.length);
  }

  @override
  Future<HouseholdModel> joinHousehold({
    required String uid,
    required String pin,
  }) async {
    final cleanPin = pin.trim();
    final pinDoc = await _firestore
        .doc(FirestorePaths.householdPin(cleanPin))
        .get();

    if (!pinDoc.exists) {
      throw const NotFoundFailure(
        'No household found with that PIN. Please check the digits.',
      );
    }

    final householdId = pinDoc.data()?[PinFields.householdId] as String? ?? '';
    if (householdId.isEmpty) {
      throw const NotFoundFailure('Household data could not be found.');
    }

    final householdDoc = await _firestore
        .doc(FirestorePaths.household(householdId))
        .get();
    if (!householdDoc.exists) {
      throw const NotFoundFailure('Household no longer exists.');
    }

    final membersSnap = await _firestore
        .collection(FirestorePaths.members(householdId))
        .get();

    final alreadyMember = membersSnap.docs.any((doc) => doc.id == uid);
    if (!alreadyMember && membersSnap.docs.length >= _maxHouseholdMembers) {
      throw const ValidationFailure(
        'This household is already full (maximum 10 members).',
      );
    }

    final memberRef = _firestore.doc(FirestorePaths.member(householdId, uid));
    final userRef = _firestore.doc(FirestorePaths.user(uid));

    final batch = _firestore.batch();
    if (!alreadyMember) {
      final newMember = MemberModel(
        uid: uid,
        role: MemberRole.member,
        credits: 0,
        joinedAt: DateTime.now(),
      );
      batch.set(memberRef, newMember.toMap());
      _activityWriter.addToBatch(
        batch,
        householdId: householdId,
        type: ActivityType.memberJoined,
        actorUid: uid,
      );
    }

    batch.set(userRef, {
      UserFields.householdId: householdId,
    }, SetOptions(merge: true));

    await batch.commit();
    return HouseholdModel.fromFirestore(householdDoc);
  }

  @override
  Future<String> regeneratePin(String householdId) async {
    final householdRef = _firestore.doc(FirestorePaths.household(householdId));
    final householdDoc = await householdRef.get();

    if (!householdDoc.exists) {
      throw const NotFoundFailure('Household was not found.');
    }

    final oldPin = (householdDoc.data()?[HouseholdFields.pin] as String?) ?? '';
    final newPin = await _generateUniquePin(
      excludePin: oldPin.isEmpty ? null : oldPin,
    );

    final newPinRef = _firestore.doc(FirestorePaths.householdPin(newPin));
    final batch = _firestore.batch();

    batch.set(newPinRef, {
      PinFields.householdId: householdId,
      PinFields.createdAt: FieldValue.serverTimestamp(),
    });

    if (oldPin.isNotEmpty) {
      final oldPinRef = _firestore.doc(FirestorePaths.householdPin(oldPin));
      batch.delete(oldPinRef);
    }

    batch.update(householdRef, {HouseholdFields.pin: newPin});
    await batch.commit();

    return newPin;
  }

  @override
  Future<void> removeMember({
    required String householdId,
    required String callerUid,
    required String targetUid,
  }) async {
    if (callerUid == targetUid) {
      throw const ValidationFailure(
        'The admin cannot remove themselves. Transfer admin rights first.',
      );
    }

    final householdDoc = await _firestore
        .doc(FirestorePaths.household(householdId))
        .get();
    if (!householdDoc.exists) {
      throw const NotFoundFailure('Household was not found.');
    }

    final adminUid = householdDoc.data()?[HouseholdFields.adminUid] as String?;
    if (adminUid != null && adminUid.isNotEmpty && adminUid != callerUid) {
      throw const PermissionFailure(
        'Only the household admin can remove members.',
      );
    }

    final targetMemberRef = _firestore.doc(
      FirestorePaths.member(householdId, targetUid),
    );
    final batch = _firestore.batch();

    batch.delete(targetMemberRef);
    _activityWriter.addToBatch(
      batch,
      householdId: householdId,
      type: ActivityType.memberRemoved,
      actorUid: callerUid,
      targetUid: targetUid,
    );

    await batch.commit();
  }

  @override
  Future<void> transferAdmin({
    required String householdId,
    required String callerUid,
    required String newAdminUid,
  }) async {
    if (callerUid == newAdminUid) {
      return;
    }

    final householdRef = _firestore.doc(FirestorePaths.household(householdId));
    final householdDoc = await householdRef.get();

    if (!householdDoc.exists) {
      throw const NotFoundFailure('Household was not found.');
    }

    final currentAdminUid =
        (householdDoc.data()?[HouseholdFields.adminUid] as String?) ??
        callerUid;
    if (currentAdminUid != callerUid) {
      throw const PermissionFailure(
        'Only the current admin can transfer admin rights.',
      );
    }

    final oldAdminMemberRef = _firestore.doc(
      FirestorePaths.member(householdId, currentAdminUid),
    );
    final newAdminMemberRef = _firestore.doc(
      FirestorePaths.member(householdId, newAdminUid),
    );

    final batch = _firestore.batch();
    batch.update(householdRef, {HouseholdFields.adminUid: newAdminUid});
    batch.update(oldAdminMemberRef, {
      MemberFields.role: MemberRole.member.name,
    });
    batch.update(newAdminMemberRef, {MemberFields.role: MemberRole.admin.name});

    await batch.commit();
  }

  @override
  Future<void> leaveHousehold({
    required String householdId,
    required String uid,
  }) async {
    final householdDoc = await _firestore
        .doc(FirestorePaths.household(householdId))
        .get();

    if (householdDoc.exists) {
      final adminUid =
          householdDoc.data()?[HouseholdFields.adminUid] as String?;
      if (adminUid == uid) {
        throw const ValidationFailure(
          'The admin cannot leave the household. Please transfer admin rights first.',
        );
      }
    }

    final memberRef = _firestore.doc(FirestorePaths.member(householdId, uid));
    final userRef = _firestore.doc(FirestorePaths.user(uid));

    final batch = _firestore.batch();
    batch.delete(memberRef);
    batch.set(userRef, {UserFields.householdId: null}, SetOptions(merge: true));

    await batch.commit();
  }

  @override
  Future<bool> checkAndClearStaleHousehold({
    required String householdId,
    required String uid,
  }) async {
    final memberDoc = await _firestore
        .doc(FirestorePaths.member(householdId, uid))
        .get();

    if (memberDoc.exists) {
      return false;
    }

    await _firestore.doc(FirestorePaths.user(uid)).set({
      UserFields.householdId: null,
    }, SetOptions(merge: true));
    return true;
  }
}
