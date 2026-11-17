import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:changa_app/core/constants/firestore_paths.dart';
import 'package:changa_app/features/activity/data/activity_writer.dart';
import 'package:changa_app/features/chores/data/chore_exceptions.dart';
import 'package:changa_app/features/chores/data/datasources/swap_remote_datasource.dart';
import 'package:changa_app/features/chores/domain/entities/chore.dart';
import 'package:changa_app/features/chores/domain/entities/swap_request.dart';
import 'package:changa_app/features/notifications/data/notification_writer.dart';

import 'chore_datasource_fixture.dart';

Matcher _ruleError(ChoreRuleKind kind) =>
    throwsA(isA<ChoreRuleException>().having((e) => e.kind, 'kind', kind));

void main() {
  late FakeFirebaseFirestore db;
  late MockFirebaseAuth auth;
  late MockUser user;
  late SwapRemoteDataSource source;

  void signInAs(String uid) => when(() => user.uid).thenReturn(uid);

  Future<void> seed({
    String assignee = 'u1',
    ChoreStatus status = ChoreStatus.pending,
  }) async {
    for (final uid in ['u1', 'u2']) {
      await db.doc(FirestorePaths.member(householdId, uid)).set({
        MemberFields.role: 'member',
        MemberFields.credits: 0,
        MemberFields.joinedAt: Timestamp.fromDate(DateTime(2026, 10, 1)),
      });
    }
    await db.doc(FirestorePaths.user('u1')).set({
      UserFields.fullName: 'Amara Okoye',
    });
    await db.doc(FirestorePaths.user('u2')).set({
      UserFields.fullName: 'Jean Baptiste',
    });
    await db.doc(FirestorePaths.chore(householdId, choreId)).set({
      ChoreFields.title: 'Dishes',
      ChoreFields.difficulty: ChoreDifficulty.easy.name,
      ChoreFields.assignedToUid: assignee,
      ChoreFields.dueDate: Timestamp.fromDate(DateTime(2026, 10, 20)),
      ChoreFields.status: status.name,
      ChoreFields.createdByUid: 'u1',
      ChoreFields.createdAt: Timestamp.fromDate(DateTime(2026, 10, 1)),
    });
  }

  Future<List<Map<String, dynamic>>> swaps() async {
    final snap = await db
        .collection(FirestorePaths.swapRequests(householdId))
        .get();
    return [
      for (final d in snap.docs) {'id': d.id, ...d.data()},
    ];
  }

  Future<List<Map<String, dynamic>>> collection(String path) async {
    final snap = await db.collection(path).get();
    return [for (final d in snap.docs) d.data()];
  }

  Future<String> openRequest() async {
    signInAs('u1');
    await source.request(
      householdId: householdId,
      choreId: choreId,
      toUid: 'u2',
    );
    return (await swaps()).single['id'] as String;
  }

  setUp(() {
    db = FakeFirebaseFirestore();
    auth = MockFirebaseAuth();
    user = MockUser();
    when(() => auth.currentUser).thenReturn(user);
    signInAs('u1');
    source = SwapRemoteDataSource(
      db,
      auth,
      ActivityWriter(firestore: db),
      NotificationWriter(db),
    );
  });

  group('requesting a swap', () {
    test('saves a pending request, a notification and an activity', () async {
      await seed();

      await source.request(
        householdId: householdId,
        choreId: choreId,
        toUid: 'u2',
        note: '  Exam week  ',
      );

      final request = (await swaps()).single;
      expect(request[SwapRequestFields.status], SwapStatus.pending.name);
      expect(request[SwapRequestFields.fromUid], 'u1');
      expect(request[SwapRequestFields.toUid], 'u2');
      expect(request[SwapRequestFields.note], 'Exam week');

      final notes = await collection(FirestorePaths.notifications(householdId));
      expect(notes, hasLength(1));
      expect(notes.single[NotificationFields.recipientUid], 'u2');
      expect(notes.single[NotificationFields.body], contains('Amara'));

      final activity = await collection(FirestorePaths.activities(householdId));
      expect(activity, hasLength(1));
      expect(activity.single[ActivityFields.type], 'swapRequested');
    });

    test('only the assignee can ask to swap', () async {
      await seed(assignee: 'u2');

      await expectLater(
        source.request(householdId: householdId, choreId: choreId, toUid: 'u2'),
        _ruleError(ChoreRuleKind.permission),
      );
      expect(await swaps(), isEmpty);
    });

    test('you cannot swap with yourself', () async {
      await seed();

      await expectLater(
        source.request(householdId: householdId, choreId: choreId, toUid: 'u1'),
        _ruleError(ChoreRuleKind.validation),
      );
    });

    test('the other person must be in the household', () async {
      await seed();

      await expectLater(
        source.request(
          householdId: householdId,
          choreId: choreId,
          toUid: 'stranger',
        ),
        _ruleError(ChoreRuleKind.validation),
      );
    });

    test('a finished chore cannot be swapped', () async {
      await seed(status: ChoreStatus.done);

      await expectLater(
        source.request(householdId: householdId, choreId: choreId, toUid: 'u2'),
        _ruleError(ChoreRuleKind.validation),
      );
    });

    test('only one request can be open for a chore', () async {
      await seed();
      await openRequest();

      await expectLater(
        source.request(householdId: householdId, choreId: choreId, toUid: 'u2'),
        _ruleError(ChoreRuleKind.validation),
      );
      expect(await swaps(), hasLength(1));
    });
  });

  group('answering a swap', () {
    test('accepting hands the chore over and tells the asker', () async {
      await seed();
      final id = await openRequest();
      signInAs('u2');

      await source.respond(
        householdId: householdId,
        requestId: id,
        accept: true,
      );

      final chore = await db
          .doc(FirestorePaths.chore(householdId, choreId))
          .get();
      expect(chore.data()?[ChoreFields.assignedToUid], 'u2');
      expect(
        (await swaps()).single[SwapRequestFields.status],
        SwapStatus.accepted.name,
      );

      final notes = await collection(FirestorePaths.notifications(householdId));
      final reply = notes.firstWhere(
        (n) => n[NotificationFields.recipientUid] == 'u1',
      );
      expect(reply[NotificationFields.body], contains('Jean'));

      final types = (await collection(FirestorePaths.activities(householdId)))
          .map((a) => a[ActivityFields.type]);
      expect(types, contains('swapAccepted'));
    });

    test('declining leaves the chore with its owner', () async {
      await seed();
      final id = await openRequest();
      signInAs('u2');

      await source.respond(
        householdId: householdId,
        requestId: id,
        accept: false,
      );

      final chore = await db
          .doc(FirestorePaths.chore(householdId, choreId))
          .get();
      expect(chore.data()?[ChoreFields.assignedToUid], 'u1');
      expect(
        (await swaps()).single[SwapRequestFields.status],
        SwapStatus.declined.name,
      );
    });

    test('only the person asked can answer', () async {
      await seed();
      final id = await openRequest();

      await expectLater(
        source.respond(householdId: householdId, requestId: id, accept: true),
        _ruleError(ChoreRuleKind.permission),
      );
    });

    test('a request cannot be answered twice', () async {
      await seed();
      final id = await openRequest();
      signInAs('u2');
      await source.respond(
        householdId: householdId,
        requestId: id,
        accept: false,
      );

      await expectLater(
        source.respond(householdId: householdId, requestId: id, accept: true),
        _ruleError(ChoreRuleKind.validation),
      );
    });

    test('accepting fails if the chore was finished meanwhile', () async {
      await seed();
      final id = await openRequest();
      await db.doc(FirestorePaths.chore(householdId, choreId)).update({
        ChoreFields.status: ChoreStatus.done.name,
      });
      signInAs('u2');

      await expectLater(
        source.respond(householdId: householdId, requestId: id, accept: true),
        _ruleError(ChoreRuleKind.validation),
      );
      expect(
        (await swaps()).single[SwapRequestFields.status],
        SwapStatus.pending.name,
      );
    });
  });

  group('cancelling a swap', () {
    test('the asker can cancel an open request', () async {
      await seed();
      final id = await openRequest();

      await source.cancel(householdId, id);

      expect(
        (await swaps()).single[SwapRequestFields.status],
        SwapStatus.cancelled.name,
      );
    });

    test('someone else cannot cancel it', () async {
      await seed();
      final id = await openRequest();
      signInAs('u2');

      await expectLater(
        source.cancel(householdId, id),
        _ruleError(ChoreRuleKind.permission),
      );
    });
  });
}
