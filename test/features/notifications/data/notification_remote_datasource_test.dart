import 'package:changa_app/core/constants/firestore_paths.dart';
import 'package:changa_app/core/error/failures.dart';
import 'package:changa_app/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late NotificationRemoteDataSource source;

  final createdAt = DateTime.utc(2026, 11, 1);

  Future<void> seed(
    String id, {
    String householdId = 'home',
    String recipient = 'me',
    bool read = false,
    DateTime? created,
  }) {
    return firestore.doc(FirestorePaths.notification(householdId, id)).set({
      NotificationFields.recipientUid: recipient,
      NotificationFields.actorUid: 'kevin',
      NotificationFields.type: 'nudge',
      NotificationFields.title: 'Friendly reminder',
      NotificationFields.body: 'Please check your balance.',
      NotificationFields.refId: 'debt-1',
      NotificationFields.read: read,
      NotificationFields.createdAt: Timestamp.fromDate(created ?? createdAt),
    });
  }

  setUp(() {
    firestore = FakeFirebaseFirestore();
    source = NotificationRemoteDataSource(firestore);
  });

  test('reads the user household and allows no household', () async {
    final user = firestore.doc(FirestorePaths.user('me'));

    await user.set({UserFields.householdId: 'home'});
    expect(await source.getHouseholdId('me'), 'home');

    await user.update({UserFields.householdId: null});
    expect(await source.getHouseholdId('me'), isNull);
  });

  test('rejects a missing user profile', () async {
    await expectLater(
      source.getHouseholdId('missing'),
      throwsA(
        isA<NotificationDataException>().having(
          (error) => error.failure,
          'failure',
          isA<NotFoundFailure>(),
        ),
      ),
    );
  });

  test('watches only this recipient unread items, newest first', () async {
    await seed('older');
    await seed('newer', created: createdAt.add(const Duration(minutes: 1)));
    await seed('already-read', read: true);
    await seed('another-recipient', recipient: 'grace');
    await seed('another-household', householdId: 'other-home');

    final notifications = await source
        .watchUnread(householdId: 'home', uid: 'me')
        .first;

    expect(notifications.map((notification) => notification.id).toList(), [
      'newer',
      'older',
    ]);
    expect(notifications.first.title, 'Friendly reminder');
    expect(
      notifications.first.createdAt.toUtc(),
      createdAt.add(const Duration(minutes: 1)),
    );
  });

  test('markRead changes only the read flag and is repeatable', () async {
    await seed('mine');

    final reference = firestore.doc(
      FirestorePaths.notification('home', 'mine'),
    );
    final before = (await reference.get()).data()!;

    await source.markRead(
      householdId: 'home',
      uid: 'me',
      notificationId: 'mine',
    );

    expect((await reference.get()).data(), {
      ...before,
      NotificationFields.read: true,
    });

    await source.markRead(
      householdId: 'home',
      uid: 'me',
      notificationId: 'mine',
    );

    expect((await reference.get()).data(), {
      ...before,
      NotificationFields.read: true,
    });
  });

  test('markRead rejects another recipient without changing data', () async {
    await seed('not-mine', recipient: 'grace');

    await expectLater(
      source.markRead(
        householdId: 'home',
        uid: 'me',
        notificationId: 'not-mine',
      ),
      throwsA(
        isA<NotificationDataException>().having(
          (error) => error.failure,
          'failure',
          isA<PermissionFailure>(),
        ),
      ),
    );

    final document = await firestore
        .doc(FirestorePaths.notification('home', 'not-mine'))
        .get();

    expect(document.data()![NotificationFields.read], isFalse);
  });

  test('markRead rejects a missing notification', () async {
    await expectLater(
      source.markRead(
        householdId: 'home',
        uid: 'me',
        notificationId: 'missing',
      ),
      throwsA(
        isA<NotificationDataException>().having(
          (error) => error.failure,
          'failure',
          isA<NotFoundFailure>(),
        ),
      ),
    );
  });

  test(
    'markAllRead handles multiple batches and isolates recipients',
    () async {
      // The data source uses batches of 400.
      for (var index = 0; index < 401; index++) {
        await seed('mine-$index');
      }
      await seed('already-read', read: true);
      await seed('grace-item', recipient: 'grace');
      await seed('other-home-item', householdId: 'other-home');

      await source.markAllRead(householdId: 'home', uid: 'me');

      final mine = await firestore
          .collection(FirestorePaths.notifications('home'))
          .where(NotificationFields.recipientUid, isEqualTo: 'me')
          .get();

      expect(mine.docs, hasLength(402));
      expect(
        mine.docs.every(
          (document) => document.data()[NotificationFields.read] == true,
        ),
        isTrue,
      );

      for (final path in [
        FirestorePaths.notification('home', 'grace-item'),
        FirestorePaths.notification('other-home', 'other-home-item'),
      ]) {
        final document = await firestore.doc(path).get();
        expect(document.data()![NotificationFields.read], isFalse);
      }

      // Repeating the operation with no unread items should succeed.
      await source.markAllRead(householdId: 'home', uid: 'me');
    },
  );
}
