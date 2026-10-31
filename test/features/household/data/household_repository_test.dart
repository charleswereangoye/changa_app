import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:changa_app/core/constants/firestore_paths.dart';
import 'package:changa_app/core/error/failures.dart';
import 'package:changa_app/features/household/data/datasources/household_remote_datasource.dart';
import 'package:changa_app/features/household/data/repositories/household_repository_impl.dart';
import 'package:changa_app/features/household/domain/entities/household.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  group('HouseholdRepository - Creation & Preview', () {
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

      // Verify Pin mapping
      final pinDoc = await fakeFirestore
          .doc(FirestorePaths.householdPin(household.pin))
          .get();
      expect(pinDoc.exists, true);
      expect(pinDoc.data()?[PinFields.householdId], household.id);

      // Verify Admin Member entry
      final memberDoc = await fakeFirestore
          .doc(FirestorePaths.member(household.id, adminUid))
          .get();
      expect(memberDoc.exists, true);
      expect(memberDoc.data()?['role'], 'admin');

      // Verify User document householdId update
      final userDoc = await fakeFirestore
          .doc(FirestorePaths.user(adminUid))
          .get();
      expect(userDoc.data()?['householdId'], household.id);
    });

    test(
      'previewHouseholdByPin returns correct metadata on valid PIN',
      () async {
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
      },
    );

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

  group('HouseholdRepository - Joining & Capacity Edge Cases', () {
    test('joinHousehold adds member successfully and logs activity', () async {
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

      // Check member sub-collection
      final memberDoc = await fakeFirestore
          .doc(FirestorePaths.member(household.id, memberUid))
          .get();
      expect(memberDoc.exists, true);
      expect(memberDoc.data()?['role'], 'member');

      // Check activity log written
      final activitiesSnap = await fakeFirestore
          .collection(FirestorePaths.activities(household.id))
          .get();
      expect(activitiesSnap.docs.length, 1);
      expect(activitiesSnap.docs.first.data()['type'], 'memberJoined');
    });

    test('joinHousehold fails with ValidationFailure when household is full (10 members)', () async {
      final adminRepo = createRepo(adminUid);
      final createRes = await adminRepo.createHousehold(
        name: 'Full House',
        type: HouseholdType.house,
        expectedMembers: 10,
      );
      final household = createRes.dataOrNull!;

      // Pre-populate 10 members in fake firestore to test max capacity rule
      for (int i = 0; i < 10; i++) {
        await fakeFirestore
            .doc(FirestorePaths.member(household.id, 'filler_user_$i'))
            .set({
              'role': 'member',
              'credits': 0,
              'joinedAt': FieldValue.serverTimestamp(),
            });
      }

      final outsiderRepo = createRepo('outsider_999');
      final joinRes = await outsiderRepo.joinHousehold(household.pin);

      expect(joinRes.isFailure, true);
      expect(joinRes.failureOrNull, isA<ValidationFailure>());
      expect(joinRes.failureOrNull?.message, contains('already full'));
    });
  });

  group('HouseholdRepository - Administration & Member Management', () {
    test(
      'regeneratePin removes old PIN document and creates a new one',
      () async {
        final repo = createRepo(adminUid);
        final createRes = await repo.createHousehold(
          name: 'Pin Rotation House',
          type: HouseholdType.apartment,
          expectedMembers: 4,
        );
        final household = createRes.dataOrNull!;
        final oldPin = household.pin;

        final regenRes = await repo.regeneratePin(household.id);
        expect(regenRes.isSuccess, true);
        final newPin = regenRes.dataOrNull!;
        expect(newPin, isNot(equals(oldPin)));

        // Verify old PIN doc is gone
        final oldPinDoc = await fakeFirestore
            .doc(FirestorePaths.householdPin(oldPin))
            .get();
        expect(oldPinDoc.exists, false);

        // Verify new PIN doc exists and maps correctly
        final newPinDoc = await fakeFirestore
            .doc(FirestorePaths.householdPin(newPin))
            .get();
        expect(newPinDoc.exists, true);
        expect(newPinDoc.data()?[PinFields.householdId], household.id);
      },
    );

    test('removeMember prevents admin from removing themselves', () async {
      final repo = createRepo(adminUid);
      final createRes = await repo.createHousehold(
        name: 'Admin Self-Guard',
        type: HouseholdType.apartment,
        expectedMembers: 2,
      );
      final household = createRes.dataOrNull!;

      // Admin tries to remove themselves
      final removeRes = await repo.removeMember(
        householdId: household.id,
        uid: adminUid,
      );

      expect(removeRes.isFailure, true);
      expect(removeRes.failureOrNull, isA<ValidationFailure>());
      expect(
        removeRes.failureOrNull?.message,
        contains('admin cannot remove themselves'),
      );
    });

    test('removeMember denies non-admin members from removing users', () async {
      final adminRepo = createRepo(adminUid);
      final createRes = await adminRepo.createHousehold(
        name: 'Permission Guard',
        type: HouseholdType.house,
        expectedMembers: 3,
      );
      final household = createRes.dataOrNull!;

      // Member joins
      final memberRepo = createRepo(memberUid);
      await memberRepo.joinHousehold(household.pin);

      // Regular member attempts to remove another user
      final unauthorizedRemoveRes = await memberRepo.removeMember(
        householdId: household.id,
        uid: otherUid,
      );

      expect(unauthorizedRemoveRes.isFailure, true);
      expect(unauthorizedRemoveRes.failureOrNull, isA<PermissionFailure>());
    });

    test(
      'leaveHousehold prevents admin from leaving without transferring rights',
      () async {
        final repo = createRepo(adminUid);
        final createRes = await repo.createHousehold(
          name: 'Admin Exit Guard',
          type: HouseholdType.apartment,
          expectedMembers: 2,
        );
        final household = createRes.dataOrNull!;

        final leaveRes = await repo.leaveHousehold(household.id);

        expect(leaveRes.isFailure, true);
        expect(leaveRes.failureOrNull, isA<ValidationFailure>());
        expect(leaveRes.failureOrNull?.message, contains('admin cannot leave'));
      },
    );
  });
}
