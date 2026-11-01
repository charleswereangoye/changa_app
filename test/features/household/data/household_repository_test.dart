import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:changa_app/core/constants/firestore_paths.dart';
import 'package:changa_app/core/error/failures.dart';
import 'package:changa_app/features/household/data/datasources/household_remote_datasource.dart';
import 'package:changa_app/features/household/data/repositories/household_repository_impl.dart';
import 'package:changa_app/features/household/domain/entities/household.dart';
import 'package:changa_app/features/household/domain/entities/member.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late HouseholdRemoteDataSource remoteDataSource;
  late String currentUid;

  const adminUid = 'admin_user_111';
  const memberUid = 'member_user_222';
  const otherUid = 'other_user_333';

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    remoteDataSource = HouseholdRemoteDataSourceImpl(firestore: fakeFirestore);
    currentUid = adminUid;
  });

  HouseholdRepositoryImpl createRepo([String? customUid]) {
    return HouseholdRepositoryImpl(
      remoteDataSource: remoteDataSource,
      currentUidResolver: () => customUid ?? currentUid,
    );
  }

  group('HouseholdRepository - Creation, Single-Household Rule & Preview', () {
    test('createHousehold succeeds and seeds pin doc, admin member, and user reference', () async {
      final repo = createRepo(adminUid);
      final result = await repo.createHousehold(
        name: 'Alpha House',
        type: HouseholdType.apartment,
        expectedMembers: 3,
      );

      expect(result.isSuccess, true);
      final household = result.dataOrNull!;
      expect(household.name, 'Alpha House');
      expect(household.adminUid, adminUid);
      expect(household.pin.length, 6);

      final pinDoc = await fakeFirestore
          .doc(FirestorePaths.householdPin(household.pin))
          .get();
      expect(pinDoc.exists, true);
      expect(pinDoc.data()?[PinFields.householdId], household.id);

      final memberDoc = await fakeFirestore
          .doc(FirestorePaths.member(household.id, adminUid))
          .get();
      expect(memberDoc.exists, true);
      expect(memberDoc.data()?[MemberFields.role], 'admin');

      final userDoc = await fakeFirestore
          .doc(FirestorePaths.user(adminUid))
          .get();
      expect(userDoc.data()?[UserFields.householdId], household.id);
    });

    test('createHousehold rejects when user already belongs to an active household', () async {
      final repo = createRepo(adminUid);
      final firstCreate = await repo.createHousehold(
        name: 'First House',
        type: HouseholdType.apartment,
        expectedMembers: 2,
      );
      expect(firstCreate.isSuccess, true);

      final secondCreate = await repo.createHousehold(
        name: 'Second House',
        type: HouseholdType.house,
        expectedMembers: 4,
      );
      expect(secondCreate.isFailure, true);
      expect(secondCreate.failureOrNull, isA<ValidationFailure>());
    });

    test('previewHouseholdByPin returns metadata on valid PIN', () async {
      final repo = createRepo(adminUid);
      final createRes = await repo.createHousehold(
        name: 'Beta Home',
        type: HouseholdType.house,
        expectedMembers: 2,
      );
      final pin = createRes.dataOrNull!.pin;

      final previewRes = await repo.previewHouseholdByPin(pin);
      expect(previewRes.isSuccess, true);
      final preview = previewRes.dataOrNull!;
      expect(preview.name, 'Beta Home');
      expect(preview.memberCount, 1);
    });

    test(
      'previewHouseholdByPin fails with NotFoundFailure on invalid PIN',
      () async {
        final repo = createRepo(adminUid);
        final previewRes = await repo.previewHouseholdByPin('999999');
        expect(previewRes.isFailure, true);
        expect(previewRes.failureOrNull, isA<NotFoundFailure>());
      },
    );
  });

  group('HouseholdRepository - Joining, Idempotency & Atomic Capacity', () {
    test('joinHousehold adds member and logs activity', () async {
      final adminRepo = createRepo(adminUid);
      final createRes = await adminRepo.createHousehold(
        name: 'Delta Dorm',
        type: HouseholdType.dorm,
        expectedMembers: 5,
      );
      final household = createRes.dataOrNull!;

      final memberRepo = createRepo(memberUid);
      final joinRes = await memberRepo.joinHousehold(household.pin);

      expect(joinRes.isSuccess, true);
      expect(joinRes.dataOrNull!.id, household.id);

      final memberDoc = await fakeFirestore
          .doc(FirestorePaths.member(household.id, memberUid))
          .get();
      expect(memberDoc.exists, true);
      expect(memberDoc.data()?[MemberFields.role], 'member');

      final activitiesSnap = await fakeFirestore
          .collection(FirestorePaths.activities(household.id))
          .get();
      expect(activitiesSnap.docs.length, 1);
      expect(
        activitiesSnap.docs.first.data()[ActivityFields.type],
        'memberJoined',
      );
    });

    test('joinHousehold allows idempotent join to the same household without duplicate activity', () async {
      final adminRepo = createRepo(adminUid);
      final household = (await adminRepo.createHousehold(
        name: 'Idempotent House',
        type: HouseholdType.apartment,
        expectedMembers: 3,
      )).dataOrNull!;

      final memberRepo = createRepo(memberUid);
      final firstJoin = await memberRepo.joinHousehold(household.pin);
      final secondJoin = await memberRepo.joinHousehold(household.pin);

      expect(firstJoin.isSuccess, true);
      expect(secondJoin.isSuccess, true);

      final activitiesSnap = await fakeFirestore
          .collection(FirestorePaths.activities(household.id))
          .get();
      expect(activitiesSnap.docs.length, 1);
    });

    test(
      'joinHousehold rejects when user already belongs to another household',
      () async {
        final admin1Repo = createRepo(adminUid);
        final house1 = (await admin1Repo.createHousehold(
          name: 'House One',
          type: HouseholdType.apartment,
          expectedMembers: 3,
        )).dataOrNull!;

        final admin2Repo = createRepo(otherUid);
        final house2 = (await admin2Repo.createHousehold(
          name: 'House Two',
          type: HouseholdType.house,
          expectedMembers: 3,
        )).dataOrNull!;

        final memberRepo = createRepo(memberUid);
        final joinFirst = await memberRepo.joinHousehold(house1.pin);
        expect(joinFirst.isSuccess, true);

        final joinSecond = await memberRepo.joinHousehold(house2.pin);
        expect(joinSecond.isFailure, true);
        expect(joinSecond.failureOrNull, isA<ValidationFailure>());
      },
    );

    test('joinHousehold serializes concurrent joins at 9 members so capacity never exceeds 10', () async {
      final adminRepo = createRepo(adminUid);
      final household = (await adminRepo.createHousehold(
        name: 'Capacity House',
        type: HouseholdType.house,
        expectedMembers: 10,
      )).dataOrNull!;

      // Admin is member #1; seed 8 more members to reach 9 members total.
      for (int i = 0; i < 8; i++) {
        await fakeFirestore
            .doc(FirestorePaths.member(household.id, 'existing_member_$i'))
            .set({
              MemberFields.role: 'member',
              MemberFields.credits: 0,
              MemberFields.joinedAt: FieldValue.serverTimestamp(),
            });
      }

      final candidate1Repo = createRepo('candidate_10');
      final candidate2Repo = createRepo('candidate_11');

      final results = await Future.wait([
        candidate1Repo.joinHousehold(household.pin),
        candidate2Repo.joinHousehold(household.pin),
      ]);

      final successCount = results.where((r) => r.isSuccess).length;
      final failureCount = results.where((r) => r.isFailure).length;

      expect(successCount, 1);
      expect(failureCount, 1);
      expect(
        results.firstWhere((r) => r.isFailure).failureOrNull,
        isA<ValidationFailure>(),
      );

      final membersSnap = await fakeFirestore
          .collection(FirestorePaths.members(household.id))
          .get();
      expect(membersSnap.docs.length, 10);
    });
  });

  group('HouseholdRepository - PIN Rotation, Removal & Chore Reassignment', () {
    test(
      'regeneratePin removes old PIN document and creates a new one',
      () async {
        final repo = createRepo(adminUid);
        final household = (await repo.createHousehold(
          name: 'Pin Rotation House',
          type: HouseholdType.apartment,
          expectedMembers: 4,
        )).dataOrNull!;
        final oldPin = household.pin;

        final regenRes = await repo.regeneratePin(household.id);
        expect(regenRes.isSuccess, true);
        final newPin = regenRes.dataOrNull!;
        expect(newPin, isNot(equals(oldPin)));

        final oldPinDoc = await fakeFirestore
            .doc(FirestorePaths.householdPin(oldPin))
            .get();
        expect(oldPinDoc.exists, false);

        final newPinDoc = await fakeFirestore
            .doc(FirestorePaths.householdPin(newPin))
            .get();
        expect(newPinDoc.exists, true);
        expect(newPinDoc.data()?[PinFields.householdId], household.id);
      },
    );

    test(
      'regeneratePin throws PermissionFailure when caller is not admin',
      () async {
        final adminRepo = createRepo(adminUid);
        final household = (await adminRepo.createHousehold(
          name: 'Pin Guard House',
          type: HouseholdType.apartment,
          expectedMembers: 3,
        )).dataOrNull!;

        final memberRepo = createRepo(memberUid);
        await memberRepo.joinHousehold(household.pin);

        final regenRes = await memberRepo.regeneratePin(household.id);
        expect(regenRes.isFailure, true);
        expect(regenRes.failureOrNull, isA<PermissionFailure>());
      },
    );

    test('removeMember prevents admin from removing themselves', () async {
      final repo = createRepo(adminUid);
      final household = (await repo.createHousehold(
        name: 'Admin Self-Guard',
        type: HouseholdType.apartment,
        expectedMembers: 2,
      )).dataOrNull!;

      final removeRes = await repo.removeMember(
        householdId: household.id,
        uid: adminUid,
      );

      expect(removeRes.isFailure, true);
      expect(removeRes.failureOrNull, isA<ValidationFailure>());
    });

    test(
      'removeMember denies non-admin and fails closed when adminUid is missing',
      () async {
        final adminRepo = createRepo(adminUid);
        final household = (await adminRepo.createHousehold(
          name: 'Permission Guard',
          type: HouseholdType.house,
          expectedMembers: 3,
        )).dataOrNull!;

        final memberRepo = createRepo(memberUid);
        await memberRepo.joinHousehold(household.pin);

        final unauthorizedRemoveRes = await memberRepo.removeMember(
          householdId: household.id,
          uid: otherUid,
        );
        expect(unauthorizedRemoveRes.isFailure, true);
        expect(unauthorizedRemoveRes.failureOrNull, isA<PermissionFailure>());

        // Corrupt/remove adminUid to verify fail-closed check
        await fakeFirestore.doc(FirestorePaths.household(household.id)).update({
          HouseholdFields.adminUid: null,
        });

        final missingAdminRes = await adminRepo.removeMember(
          householdId: household.id,
          uid: memberUid,
        );
        expect(missingAdminRes.isFailure, true);
        expect(missingAdminRes.failureOrNull, isA<PermissionFailure>());
      },
    );

    test('removeMember returns NotFoundFailure for non-member and does not log activity', () async {
      final adminRepo = createRepo(adminUid);
      final household = (await adminRepo.createHousehold(
        name: 'Non-Member Guard',
        type: HouseholdType.apartment,
        expectedMembers: 3,
      )).dataOrNull!;

      final res = await adminRepo.removeMember(
        householdId: household.id,
        uid: 'non_existent_member',
      );

      expect(res.isFailure, true);
      expect(res.failureOrNull, isA<NotFoundFailure>());

      final activitiesSnap = await fakeFirestore
          .collection(FirestorePaths.activities(household.id))
          .get();
      expect(activitiesSnap.docs, isEmpty);
    });

    test('removeMember reassigns pending chores to admin while keeping completed chores unchanged', () async {
      final adminRepo = createRepo(adminUid);
      final household = (await adminRepo.createHousehold(
        name: 'Chore Reassign House',
        type: HouseholdType.house,
        expectedMembers: 3,
      )).dataOrNull!;

      final memberRepo = createRepo(memberUid);
      await memberRepo.joinHousehold(household.pin);

      final pendingChoreRef = fakeFirestore.doc(
        FirestorePaths.chore(household.id, 'chore_pending_1'),
      );
      final doneChoreRef = fakeFirestore.doc(
        FirestorePaths.chore(household.id, 'chore_done_1'),
      );

      await pendingChoreRef.set({
        ChoreFields.title: 'Take out trash',
        ChoreFields.assignedToUid: memberUid,
        ChoreFields.status: 'pending',
      });
      await doneChoreRef.set({
        ChoreFields.title: 'Wash dishes',
        ChoreFields.assignedToUid: memberUid,
        ChoreFields.status: 'done',
      });

      final removeRes = await adminRepo.removeMember(
        householdId: household.id,
        uid: memberUid,
      );
      expect(removeRes.isSuccess, true);

      final updatedPending = await pendingChoreRef.get();
      final updatedDone = await doneChoreRef.get();

      expect(updatedPending.data()?[ChoreFields.assignedToUid], adminUid);
      expect(updatedDone.data()?[ChoreFields.assignedToUid], memberUid);
    });

    test('transferAdmin updates roles and household adminUid, and guards permissions', () async {
      final adminRepo = createRepo(adminUid);
      final household = (await adminRepo.createHousehold(
        name: 'Transfer House',
        type: HouseholdType.apartment,
        expectedMembers: 3,
      )).dataOrNull!;

      final memberRepo = createRepo(memberUid);
      await memberRepo.joinHousehold(household.pin);

      // Non-admin cannot transfer admin rights
      final unauthorizedTransfer = await memberRepo.transferAdmin(
        householdId: household.id,
        newAdminUid: memberUid,
      );
      expect(unauthorizedTransfer.isFailure, true);
      expect(unauthorizedTransfer.failureOrNull, isA<PermissionFailure>());

      // Admin cannot transfer to non-member
      final nonMemberTransfer = await adminRepo.transferAdmin(
        householdId: household.id,
        newAdminUid: 'stranger_uid',
      );
      expect(nonMemberTransfer.isFailure, true);
      expect(nonMemberTransfer.failureOrNull, isA<NotFoundFailure>());

      // Valid transfer
      final validTransfer = await adminRepo.transferAdmin(
        householdId: household.id,
        newAdminUid: memberUid,
      );
      expect(validTransfer.isSuccess, true);

      final updatedHousehold = await fakeFirestore
          .doc(FirestorePaths.household(household.id))
          .get();
      final oldAdminDoc = await fakeFirestore
          .doc(FirestorePaths.member(household.id, adminUid))
          .get();
      final newAdminDoc = await fakeFirestore
          .doc(FirestorePaths.member(household.id, memberUid))
          .get();

      expect(updatedHousehold.data()?[HouseholdFields.adminUid], memberUid);
      expect(oldAdminDoc.data()?[MemberFields.role], MemberRole.member.name);
      expect(newAdminDoc.data()?[MemberFields.role], MemberRole.admin.name);
    });

    test(
      'leaveHousehold prevents admin from leaving without transferring rights',
      () async {
        final repo = createRepo(adminUid);
        final household = (await repo.createHousehold(
          name: 'Admin Exit Guard',
          type: HouseholdType.apartment,
          expectedMembers: 2,
        )).dataOrNull!;

        final leaveRes = await repo.leaveHousehold(household.id);

        expect(leaveRes.isFailure, true);
        expect(leaveRes.failureOrNull, isA<ValidationFailure>());
      },
    );

    test('watchHousehold and watchMembers stream updates and clear stale householdId', () async {
      final adminRepo = createRepo(adminUid);
      final household = (await adminRepo.createHousehold(
        name: 'Stream House',
        type: HouseholdType.apartment,
        expectedMembers: 3,
      )).dataOrNull!;

      final memberRepo = createRepo(memberUid);
      await memberRepo.joinHousehold(household.pin);

      final streamedHousehold = await adminRepo
          .watchHousehold(household.id)
          .first;
      expect(streamedHousehold?.id, household.id);

      await adminRepo.removeMember(householdId: household.id, uid: memberUid);

      final membersList = await memberRepo.watchMembers(household.id).first;
      expect(membersList.any((m) => m.uid == memberUid), false);

      final removedUserDoc = await fakeFirestore
          .doc(FirestorePaths.user(memberUid))
          .get();
      expect(removedUserDoc.data()?[UserFields.householdId], isNull);
    });
  });
}
