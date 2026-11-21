import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:changa_app/core/constants/firestore_paths.dart';
import 'package:changa_app/core/error/failures.dart';
import 'package:changa_app/core/error/result.dart';
import 'package:changa_app/features/debts/data/datasources/debt_remote_datasource.dart';
import 'package:changa_app/features/debts/data/models/debt_model.dart';
import 'package:changa_app/features/debts/data/repositories/debt_repository_impl.dart';
import 'package:changa_app/features/debts/domain/usecases/send_nudge.dart';

import '../../../helpers/test_data.dart';

class _MockAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

void main() {
  late FakeFirebaseFirestore firestore;
  late _MockAuth auth;
  late SendNudge sendNudge;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    auth = _MockAuth();
    final user = _MockUser();

    when(() => user.uid).thenReturn(testCurrentUid);
    when(() => auth.currentUser).thenReturn(user);

    sendNudge = SendNudge(
      DebtRepositoryImpl(DebtRemoteDataSource(firestore), auth),
    );

    await firestore.doc(FirestorePaths.household(testHouseholdId)).set({
      HouseholdFields.name: 'Kigali Nest',
    });

    await firestore.doc(FirestorePaths.user(testOtherUid)).set({
      UserFields.fullName: 'Jean',
    });

    final debt = testDebt();

    await firestore
        .doc(FirestorePaths.debt(testHouseholdId, debt.id))
        .set(DebtModel.fromEntity(debt).toMap());
  });

  Future<Result<void>> send() {
    return sendNudge(
      householdId: testHouseholdId,
      fromUid: testCurrentUid,
      toUid: testOtherUid,
    );
  }

  Future<int> count(String path) async {
    return (await firestore.collection(path).get()).size;
  }

  Future<void> seedPreviousNudge(Duration age) async {
    await firestore.collection(FirestorePaths.activities(testHouseholdId)).add({
      ActivityFields.type: 'nudgeSent',
      ActivityFields.actorUid: testCurrentUid,
      ActivityFields.targetUid: testOtherUid,
      ActivityFields.createdAt: Timestamp.fromDate(
        DateTime.now().subtract(age),
      ),
    });
  }

  test('first nudge creates a recipient notification and activity', () async {
    final result = await send();

    expect(result.isSuccess, isTrue);

    final notices = await firestore
        .collection(FirestorePaths.notifications(testHouseholdId))
        .get();

    expect(notices.docs, hasLength(1));

    final notice = notices.docs.single.data();

    expect(notice[NotificationFields.type], 'nudge');
    expect(notice[NotificationFields.actorUid], testCurrentUid);
    expect(notice[NotificationFields.recipientUid], testOtherUid);
    expect(notice[NotificationFields.read], isFalse);
    expect(notice[NotificationFields.body], contains('RWF 6,000'));

    expect(await count(FirestorePaths.activities(testHouseholdId)), 1);
  });

  test('a second immediate nudge is refused without extra writes', () async {
    expect((await send()).isSuccess, isTrue);

    final second = await send();

    expect(second.isFailure, isTrue);
    expect(second.failureOrNull, isA<NudgeCooldownFailure>());

    expect(await count(FirestorePaths.notifications(testHouseholdId)), 1);
    expect(await count(FirestorePaths.activities(testHouseholdId)), 1);
  });

  test('a previous nudge within 24 hours blocks another nudge', () async {
    await seedPreviousNudge(const Duration(hours: 23));

    final result = await send();

    expect(result.failureOrNull, isA<NudgeCooldownFailure>());
    expect(await count(FirestorePaths.notifications(testHouseholdId)), 0);
    expect(await count(FirestorePaths.activities(testHouseholdId)), 1);
  });

  test('a previous nudge 25 hours ago allows another nudge', () async {
    await seedPreviousNudge(const Duration(hours: 25));

    final result = await send();

    expect(result.isSuccess, isTrue);
    expect(await count(FirestorePaths.notifications(testHouseholdId)), 1);
    expect(await count(FirestorePaths.activities(testHouseholdId)), 2);
  });

  test('a signed-out user cannot send a nudge', () async {
    when(() => auth.currentUser).thenReturn(null);

    final result = await send();

    expect(result.failureOrNull, isA<AuthFailure>());
    expect(await count(FirestorePaths.notifications(testHouseholdId)), 0);
    expect(await count(FirestorePaths.activities(testHouseholdId)), 0);
  });

  test('a user cannot send a nudge as another member', () async {
    final result = await sendNudge(
      householdId: testHouseholdId,
      fromUid: testOtherUid,
      toUid: testCurrentUid,
    );

    expect(result.failureOrNull, isA<PermissionFailure>());
    expect(await count(FirestorePaths.notifications(testHouseholdId)), 0);
    expect(await count(FirestorePaths.activities(testHouseholdId)), 0);
  });
}
