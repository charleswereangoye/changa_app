import 'package:changa_app/core/error/failures.dart';
import 'package:changa_app/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:changa_app/features/notifications/data/models/notification_model.dart';
import 'package:changa_app/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

class _MockSource extends Mock implements NotificationRemoteDataSource {}

void main() {
  late _MockAuth auth;
  late _MockUser user;
  late _MockSource source;
  late NotificationRepositoryImpl repository;

  setUp(() {
    auth = _MockAuth();
    user = _MockUser();
    source = _MockSource();
    repository = NotificationRepositoryImpl(source, auth);

    when(() => user.uid).thenReturn('me');
    when(() => auth.currentUser).thenReturn(user);
    when(() => source.getHouseholdId('me')).thenAnswer((_) async => 'home');
  });

  test('watchUnread rejects a signed-out user', () async {
    when(() => auth.currentUser).thenReturn(null);

    await expectLater(
      repository.watchUnread('me'),
      emitsError(isA<AuthFailure>()),
    );

    verifyNever(() => source.getHouseholdId(any()));
  });

  test('watchUnread rejects another user UID', () async {
    await expectLater(
      repository.watchUnread('grace'),
      emitsError(isA<PermissionFailure>()),
    );

    verifyNever(() => source.getHouseholdId(any()));
  });

  test('watchUnread returns an empty inbox without a household', () async {
    when(() => source.getHouseholdId('me')).thenAnswer((_) async => null);

    await expectLater(
      repository.watchUnread('me'),
      emitsInOrder([isEmpty, emitsDone]),
    );
  });

  test('watchUnread maps Firestore permission errors', () async {
    when(() => source.watchUnread(householdId: 'home', uid: 'me')).thenAnswer(
      (_) => Stream<List<NotificationModel>>.error(
        FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
      ),
    );

    await expectLater(
      repository.watchUnread('me'),
      emitsError(isA<PermissionFailure>()),
    );
  });

  test('markRead forwards the current user and household', () async {
    when(
      () => source.markRead(
        householdId: 'home',
        uid: 'me',
        notificationId: 'notification-1',
      ),
    ).thenAnswer((_) async {});

    final result = await repository.markRead('notification-1');

    expect(result.isSuccess, isTrue);

    verify(
      () => source.markRead(
        householdId: 'home',
        uid: 'me',
        notificationId: 'notification-1',
      ),
    ).called(1);
  });

  test('markRead rejects a blank notification ID', () async {
    final result = await repository.markRead('   ');

    expect(result.failureOrNull, isA<ValidationFailure>());
    verifyNever(() => source.getHouseholdId(any()));
  });

  test('markRead rejects a signed-out user', () async {
    when(() => auth.currentUser).thenReturn(null);

    final result = await repository.markRead('notification-1');

    expect(result.failureOrNull, isA<AuthFailure>());
    verifyNever(() => source.getHouseholdId(any()));
  });

  test('markRead maps unavailable errors to NetworkFailure', () async {
    when(
      () => source.markRead(
        householdId: 'home',
        uid: 'me',
        notificationId: 'notification-1',
      ),
    ).thenThrow(
      FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
    );

    final result = await repository.markRead('notification-1');

    expect(result.failureOrNull, isA<NetworkFailure>());
  });

  test('markRead preserves a data source failure', () async {
    const failure = NotFoundFailure('Notification was deleted.');

    when(
      () => source.markRead(
        householdId: 'home',
        uid: 'me',
        notificationId: 'notification-1',
      ),
    ).thenThrow(const NotificationDataException(failure));

    final result = await repository.markRead('notification-1');

    expect(result.failureOrNull, same(failure));
  });

  test('markAllRead rejects another user UID', () async {
    final result = await repository.markAllRead('grace');

    expect(result.failureOrNull, isA<PermissionFailure>());
    verifyNever(() => source.getHouseholdId(any()));
  });

  test('markAllRead requires a household', () async {
    when(() => source.getHouseholdId('me')).thenAnswer((_) async => null);

    final result = await repository.markAllRead('me');

    expect(result.failureOrNull, isA<ValidationFailure>());
  });

  test('markAllRead forwards the current session', () async {
    when(() => source.markAllRead(householdId: 'home', uid: 'me'))
        .thenAnswer((_) async {});

    final result = await repository.markAllRead('me');

    expect(result.isSuccess, isTrue);

    verify(() => source.markAllRead(householdId: 'home', uid: 'me')).called(1);
  });
}
