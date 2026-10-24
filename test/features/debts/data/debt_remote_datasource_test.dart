// Tests debt queries, settlement writes, and sequential nudges.

import 'package:changa_app/core/constants/firestore_paths.dart';
import 'package:changa_app/core/error/failures.dart';
import 'package:changa_app/features/debts/data/datasources/debt_remote_datasource.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late DebtRemoteDataSource source;

  const householdId = 'household-1';

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    source = DebtRemoteDataSource(firestore);

    await firestore.doc(FirestorePaths.user('me')).set({
      UserFields.fullName: 'Amara',
    });

    await firestore.doc(FirestorePaths.user('kevin')).set({
      UserFields.fullName: 'Kevin',
    });

    await firestore.doc(FirestorePaths.household(householdId)).set({
      HouseholdFields.name: 'Kigali Nest',
    });
  });

  Future<void> seedDebt({
    required String id,
    required String debtor,
    required String creditor,
    required int amount,
    String status = 'pending',
    DateTime? createdAt,
  }) {
    return firestore.doc(FirestorePaths.debt(householdId, id)).set({
      DebtFields.expenseId: 'expense-$id',
      DebtFields.debtorUid: debtor,
      DebtFields.creditorUid: creditor,
      DebtFields.amount: amount,
      DebtFields.creditsApplied: 0,
      DebtFields.status: status,
      DebtFields.settlementMethod: null,
      DebtFields.settledAt: null,
      DebtFields.createdAt: Timestamp.fromDate(
        createdAt ?? DateTime.utc(2026, 10, 20),
      ),
    });
  }

  Future<QuerySnapshot<Map<String, dynamic>>> notifications() {
    return firestore
        .collection(FirestorePaths.notifications(householdId))
        .get();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> activities() {
    return firestore.collection(FirestorePaths.activities(householdId)).get();
  }

  test('pending query excludes settled debts', () async {
    await seedDebt(
      id: 'pending',
      debtor: 'kevin',
      creditor: 'me',
      amount: 6000,
    );
    await seedDebt(
      id: 'settled',
      debtor: 'kevin',
      creditor: 'me',
      amount: 2000,
      status: 'settled',
    );

    final result = await source.watchPendingDebts(householdId).first;

    expect(result.map((debt) => debt.id), ['pending']);
  });

  test('since query includes recent pending and settled debts', () async {
    await seedDebt(
      id: 'recent-pending',
      debtor: 'kevin',
      creditor: 'me',
      amount: 6000,
      createdAt: DateTime.utc(2026, 10, 22),
    );
    await seedDebt(
      id: 'recent-settled',
      debtor: 'kevin',
      creditor: 'me',
      amount: 2000,
      status: 'settled',
      createdAt: DateTime.utc(2026, 10, 23),
    );
    await seedDebt(
      id: 'old',
      debtor: 'kevin',
      creditor: 'me',
      amount: 1000,
      createdAt: DateTime.utc(2026, 9, 1),
    );

    final result = await source
        .watchDebtsSince(householdId, DateTime.utc(2026, 10, 1))
        .first;

    expect(
      result.map((debt) => debt.id),
      unorderedEquals(['recent-pending', 'recent-settled']),
    );
  });

  test('between query includes both directions, newest first', () async {
    await seedDebt(
      id: 'older',
      debtor: 'kevin',
      creditor: 'me',
      amount: 6000,
      createdAt: DateTime.utc(2026, 10, 20),
    );
    await seedDebt(
      id: 'newer',
      debtor: 'me',
      creditor: 'kevin',
      amount: 2000,
      createdAt: DateTime.utc(2026, 10, 21),
    );
    await seedDebt(
      id: 'other-person',
      debtor: 'grace',
      creditor: 'me',
      amount: 3000,
    );

    final result = await source
        .watchDebtsBetween(householdId, 'me', 'kevin')
        .first;

    expect(result.map((debt) => debt.id), ['newer', 'older']);
  });

  test(
    'settlement updates both directions and adds one log and notice',
    () async {
      await seedDebt(
        id: 'incoming',
        debtor: 'kevin',
        creditor: 'me',
        amount: 6000,
      );
      await seedDebt(
        id: 'outgoing',
        debtor: 'me',
        creditor: 'kevin',
        amount: 2000,
      );
      await seedDebt(
        id: 'unrelated',
        debtor: 'grace',
        creditor: 'me',
        amount: 3000,
      );

      await source.settleBetween(
        householdId: householdId,
        meUid: 'me',
        otherUid: 'kevin',
        method: 'momo',
      );

      for (final id in ['incoming', 'outgoing']) {
        final document = await firestore
            .doc(FirestorePaths.debt(householdId, id))
            .get();
        final data = document.data()!;

        expect(data[DebtFields.status], 'settled');
        expect(data[DebtFields.settlementMethod], 'momo');
        expect(data[DebtFields.settledAt], isA<Timestamp>());
        expect(data[DebtFields.expenseId], 'expense-$id');
        expect(data[DebtFields.creditsApplied], 0);
        expect(
          data[DebtFields.createdAt],
          Timestamp.fromDate(DateTime.utc(2026, 10, 20)),
        );
        expect(data[DebtFields.amount], id == 'incoming' ? 6000 : 2000);
      }

      final unrelated = await firestore
          .doc(FirestorePaths.debt(householdId, 'unrelated'))
          .get();
      expect(unrelated.data()![DebtFields.status], 'pending');

      final logs = await activities();
      expect(logs.docs, hasLength(1));
      expect(logs.docs.single.data()[ActivityFields.amount], 4000);

      final notices = await notifications();
      expect(notices.docs, hasLength(1));

      final notice = notices.docs.single.data();
      expect(notice[NotificationFields.type], 'settled');
      expect(notice[NotificationFields.actorUid], 'me');
      expect(notice[NotificationFields.recipientUid], 'kevin');
      expect(notice[NotificationFields.body], contains('Mobile Money'));
    },
  );

  test('repeating a completed settlement creates no extra records', () async {
    await seedDebt(id: 'debt', debtor: 'kevin', creditor: 'me', amount: 6000);

    for (var attempt = 0; attempt < 2; attempt++) {
      await source.settleBetween(
        householdId: householdId,
        meUid: 'me',
        otherUid: 'kevin',
        method: 'cash',
      );
    }

    expect((await notifications()).docs, hasLength(1));
    expect((await activities()).docs, hasLength(1));
  });

  test('first nudge saves records and a second nudge is refused', () async {
    await seedDebt(
      id: 'incoming',
      debtor: 'kevin',
      creditor: 'me',
      amount: 6000,
    );
    await seedDebt(
      id: 'outgoing',
      debtor: 'me',
      creditor: 'kevin',
      amount: 2000,
    );

    final first = await source.sendNudge(
      householdId: householdId,
      fromUid: 'me',
      toUid: 'kevin',
    );

    expect(first, isNull);

    final notices = await notifications();
    expect(notices.docs, hasLength(1));

    final notice = notices.docs.single.data();
    expect(notice[NotificationFields.type], 'nudge');
    expect(notice[NotificationFields.actorUid], 'me');
    expect(notice[NotificationFields.recipientUid], 'kevin');
    expect(notice[NotificationFields.read], isFalse);
    expect(notice[NotificationFields.body], contains('RWF 4,000'));

    final logs = await activities();
    expect(logs.docs, hasLength(1));
    expect(logs.docs.single.data()[ActivityFields.amount], isNull);

    final second = await source.sendNudge(
      householdId: householdId,
      fromUid: 'me',
      toUid: 'kevin',
    );

    expect(second, isA<NudgeCooldownFailure>());
    expect((await notifications()).docs, hasLength(1));
    expect((await activities()).docs, hasLength(1));
  });

  test('a person who owes money cannot nudge their creditor', () async {
    await seedDebt(
      id: 'outgoing',
      debtor: 'me',
      creditor: 'kevin',
      amount: 6000,
    );

    final failure = await source.sendNudge(
      householdId: householdId,
      fromUid: 'me',
      toUid: 'kevin',
    );

    expect(failure, isA<ValidationFailure>());
    expect((await notifications()).docs, isEmpty);
    expect((await activities()).docs, isEmpty);
  });
}
