import 'dart:async';

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

  Future<String> regeneratePin({
    required String householdId,
    required String callerUid,
  });

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
  Future<void> _transactionQueue = Future<void>.value();

  HouseholdRemoteDataSourceImpl({
    FirebaseFirestore? firestore,
    ActivityWriter? activityWriter,
    String Function()? pinGenerator,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _activityWriter = activityWriter ?? ActivityWriter(firestore: firestore),
       _pinGenerator = pinGenerator ?? PinGenerator.generate;

  /// Serializes transactions in-process so concurrent callers in tests and
  /// single-isolate clients cannot interleave reads before commit.
  Future<T> _runSerializedTransaction<T>(
    Future<T> Function(Transaction tx) action,
  ) {
    final previous = _transactionQueue;
    final completer = Completer<void>();
    _transactionQueue = completer.future;

    return previous
        .then((_) {
          return _firestore.runTransaction<T>(action);
        })
        .whenComplete(() {
          completer.complete();
        });
  }

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

  Future<bool> _hasActiveMembershipConflict({
    required String uid,
    String? allowedHouseholdId,
  }) async {
    final userDoc = await _firestore.doc(FirestorePaths.user(uid)).get();
    final existingHouseholdId =
        userDoc.data()?[UserFields.householdId] as String?;

    if (existingHouseholdId == null ||
        existingHouseholdId.isEmpty ||
        existingHouseholdId == allowedHouseholdId) {
      return false;
    }

    final existingHouseholdDoc = await _firestore
        .doc(FirestorePaths.household(existingHouseholdId))
        .get();
    final existingMemberDoc = await _firestore
        .doc(FirestorePaths.member(existingHouseholdId, uid))
        .get();

    // Conflict if the user is still in the existing household's members list,
    // or if a test seeded users/{uid}.householdId directly without a household doc.
    return !existingHouseholdDoc.exists || existingMemberDoc.exists;
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
    if (await _hasActiveMembershipConflict(uid: uid)) {
      throw const ValidationFailure(
        'You already belong to a household. Leave your current household first.',
      );
    }

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

    return _runSerializedTransaction<HouseholdModel>((tx) async {
      final pinRef = _firestore.doc(FirestorePaths.householdPin(cleanPin));
      final pinDoc = await tx.get(pinRef);

      if (!pinDoc.exists) {
        throw const NotFoundFailure(
          'No household found with that PIN. Please check the digits.',
        );
      }

      final householdId =
          pinDoc.data()?[PinFields.householdId] as String? ?? '';
      if (householdId.isEmpty) {
        throw const NotFoundFailure('Household data could not be found.');
      }

      final householdRef = _firestore.doc(
        FirestorePaths.household(householdId),
      );
      final householdDoc = await tx.get(householdRef);
      if (!householdDoc.exists) {
        throw const NotFoundFailure('Household no longer exists.');
      }

      if (await _hasActiveMembershipConflict(
        uid: uid,
        allowedHouseholdId: householdId,
      )) {
        throw const ValidationFailure(
          'You already belong to another household. Leave it before joining a new one.',
        );
      }

      final memberRef = _firestore.doc(FirestorePaths.member(householdId, uid));
      final memberDoc = await tx.get(memberRef);
      final membersSnap = await _firestore
          .collection(FirestorePaths.members(householdId))
          .get();

      final alreadyMember =
          memberDoc.exists || membersSnap.docs.any((doc) => doc.id == uid);
      if (!alreadyMember && membersSnap.docs.length >= _maxHouseholdMembers) {
        throw const ValidationFailure(
          'This household is already full (maximum 10 members).',
        );
      }

      final userRef = _firestore.doc(FirestorePaths.user(uid));

      if (!alreadyMember) {
        final newMember = MemberModel(
          uid: uid,
          role: MemberRole.member,
          credits: 0,
          joinedAt: DateTime.now(),
        );
        tx.set(memberRef, newMember.toMap());
        _activityWriter.addToTransaction(
          tx,
          householdId: householdId,
          type: ActivityType.memberJoined,
          actorUid: uid,
        );
      }

      tx.set(userRef, {
        UserFields.householdId: householdId,
      }, SetOptions(merge: true));

      return HouseholdModel.fromFirestore(householdDoc);
    });
  }

  @override
  Future<String> regeneratePin({
    required String householdId,
    required String callerUid,
  }) async {
    final householdRef = _firestore.doc(FirestorePaths.household(householdId));
    final householdDoc = await householdRef.get();

    if (!householdDoc.exists) {
      throw const NotFoundFailure('Household was not found.');
    }

    final adminUid = householdDoc.data()?[HouseholdFields.adminUid] as String?;
    if (adminUid != callerUid) {
      throw const PermissionFailure(
        'Only the household admin can regenerate the PIN.',
      );
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
    final householdDoc = await _firestore
        .doc(FirestorePaths.household(householdId))
        .get();
    if (!householdDoc.exists) {
      throw const NotFoundFailure('Household was not found.');
    }

    final adminUid = householdDoc.data()?[HouseholdFields.adminUid] as String?;
    if (adminUid != callerUid) {
      throw const PermissionFailure(
        'Only the household admin can remove members.',
      );
    }

    if (callerUid == targetUid) {
      throw const ValidationFailure(
        'The admin cannot remove themselves. Transfer admin rights first.',
      );
    }

    final targetMemberRef = _firestore.doc(
      FirestorePaths.member(householdId, targetUid),
    );
    final targetMemberDoc = await targetMemberRef.get();
    if (!targetMemberDoc.exists) {
      throw const NotFoundFailure('Member was not found in this household.');
    }

    final pendingChoresSnap = await _firestore
        .collection(FirestorePaths.chores(householdId))
        .where(ChoreFields.assignedToUid, isEqualTo: targetUid)
        .where(ChoreFields.status, isEqualTo: 'pending')
        .get();

    final batch = _firestore.batch();
    batch.delete(targetMemberRef);

    for (final choreDoc in pendingChoresSnap.docs) {
      batch.update(choreDoc.reference, {ChoreFields.assignedToUid: adminUid});
    }

    _activityWriter.addToBatch(
      batch,
      householdId: householdId,
      type: ActivityType.memberRemoved,
      actorUid: callerUid,
      targetUid: targetUid,
    );

    // Note: users/{targetUid}.householdId is not modified directly by the
    // admin here because Firestore security rules restrict users/{uid} writes
    // to the authenticated owner of that user document. Instead, when the
    // removed user's client observes watchMembers, checkAndClearStaleHousehold
    // detects the missing member document and resets their own
    // users/{uid}.householdId to null.
    await batch.commit();
  }

  @override
  Future<void> transferAdmin({
    required String householdId,
    required String callerUid,
    required String newAdminUid,
  }) async {
    final householdRef = _firestore.doc(FirestorePaths.household(householdId));
    final householdDoc = await householdRef.get();

    if (!householdDoc.exists) {
      throw const NotFoundFailure('Household was not found.');
    }

    final currentAdminUid =
        householdDoc.data()?[HouseholdFields.adminUid] as String?;
    if (currentAdminUid != callerUid) {
      throw const PermissionFailure(
        'Only the current admin can transfer admin rights.',
      );
    }

    if (callerUid == newAdminUid) {
      return;
    }

    final newAdminMemberRef = _firestore.doc(
      FirestorePaths.member(householdId, newAdminUid),
    );
    final newAdminMemberDoc = await newAdminMemberRef.get();
    if (!newAdminMemberDoc.exists) {
      throw const NotFoundFailure(
        'New admin must be an existing household member.',
      );
    }

    final oldAdminMemberRef = _firestore.doc(
      FirestorePaths.member(householdId, callerUid),
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
