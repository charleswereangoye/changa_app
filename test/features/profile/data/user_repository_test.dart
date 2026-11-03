import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:changa_app/core/constants/firestore_paths.dart';
import 'package:changa_app/core/error/failures.dart';
import 'package:changa_app/features/profile/data/datasources/user_remote_datasource.dart';
import 'package:changa_app/features/profile/data/repositories/user_repository_impl.dart';
import 'package:changa_app/features/profile/domain/usecases/get_users_by_ids.dart';
import 'package:changa_app/features/profile/domain/usecases/update_profile.dart';
import 'package:changa_app/features/profile/domain/usecases/watch_user.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late UserRemoteDataSource remoteDataSource;
  late String currentUid;

  const user1Uid = 'user_111';
  const user2Uid = 'user_222';
  const unknownUid = 'unknown_999';

  setUp(() async {
    fakeFirestore = FakeFirebaseFirestore();
    remoteDataSource = UserRemoteDataSourceImpl(firestore: fakeFirestore);
    currentUid = user1Uid;

    // Seed test user profile in Firestore
    await fakeFirestore.doc(FirestorePaths.user(user1Uid)).set({
      UserFields.fullName: 'Alice Mukamana',
      UserFields.email: 'alice@example.com',
      UserFields.phone: '+250788111222',
      UserFields.householdId: 'house_abc',
      UserFields.createdAt: Timestamp.now(),
    });

    await fakeFirestore.doc(FirestorePaths.user(user2Uid)).set({
      UserFields.fullName: 'Bob Kayitesi',
      UserFields.email: 'bob@example.com',
      UserFields.phone: '+250788333444',
      UserFields.householdId: 'house_abc',
      UserFields.createdAt: Timestamp.now(),
    });
  });

  UserRepositoryImpl createRepo([String? customUid]) {
    return UserRepositoryImpl(
      remoteDataSource: remoteDataSource,
      currentUidResolver: () => customUid ?? currentUid,
    );
  }

  group('UserRepository - getUsersByIds', () {
    test('returns empty list when provided with empty uids', () async {
      final repo = createRepo();
      final result = await repo.getUsersByIds([]);

      expect(result.isSuccess, true);
      expect(result.dataOrNull, isEmpty);
    });

    test('fetches multiple users with correct names and fields', () async {
      final repo = createRepo();
      final result = await repo.getUsersByIds([user1Uid, user2Uid]);

      expect(result.isSuccess, true);
      final users = result.dataOrNull!;
      expect(users.length, 2);
      expect(users[0].uid, user1Uid);
      expect(users[0].fullName, 'Alice Mukamana');
      expect(users[0].householdId, 'house_abc');
      expect(users[1].uid, user2Uid);
      expect(users[1].fullName, 'Bob Kayitesi');
    });

    test('falls back gracefully to Former member for missing user with stable createdAt', () async {
      final repo = createRepo();
      final result1 = await repo.getUsersByIds([unknownUid]);
      final result2 = await repo.getUsersByIds([unknownUid]);

      expect(result1.isSuccess, true);
      expect(result2.isSuccess, true);
      final user1 = result1.dataOrNull!.first;
      final user2 = result2.dataOrNull!.first;

      expect(user1.fullName, 'Former member');
      expect(user1.createdAt, DateTime.fromMillisecondsSinceEpoch(0));
      // AppUser uses Equatable props: verify user1 == user2 across calls
      expect(user1, equals(user2));
    });

    test('GetUsersByIds use case forwards call to repository', () async {
      final repo = createRepo();
      final useCase = GetUsersByIds(repo);
      final result = await useCase([user1Uid]);

      expect(result.isSuccess, true);
      expect(result.dataOrNull!.first.fullName, 'Alice Mukamana');
    });
  });

  group('UserRepository - watchUser', () {
    test('emits user data as it changes', () async {
      final repo = createRepo();
      final stream = repo.watchUser(user1Uid);

      final user = await stream.first;
      expect(user?.fullName, 'Alice Mukamana');

      final watchUseCase = WatchUser(repo);
      final useCaseStream = watchUseCase(user1Uid);
      final userFromUseCase = await useCaseStream.first;
      expect(userFromUseCase?.fullName, 'Alice Mukamana');
    });
  });

  group('UserRepository - updateProfile', () {
    test('successfully updates user profile in Firestore', () async {
      final repo = createRepo(user1Uid);
      final result = await repo.updateProfile(
        fullName: 'Alice M. Kaneza',
        phone: '+250788999000',
      );

      expect(result.isSuccess, true);
      final updated = result.dataOrNull!;
      expect(updated.fullName, 'Alice M. Kaneza');
      expect(updated.phone, '+250788999000');

      // Verify persistence in Firestore
      final doc = await fakeFirestore.doc(FirestorePaths.user(user1Uid)).get();
      expect(doc.data()?[UserFields.fullName], 'Alice M. Kaneza');
      expect(doc.data()?[UserFields.phone], '+250788999000');
    });

    test('rejects updateProfile when signed out', () async {
      final repo = UserRepositoryImpl(
        remoteDataSource: remoteDataSource,
        currentUidResolver: () => null,
      );

      final result = await repo.updateProfile(fullName: 'New Name');
      expect(result.isFailure, true);
      expect(result.failureOrNull, isA<AuthFailure>());
    });

    test('rejects updateProfile when fullName is blank whitespace', () async {
      final repo = createRepo(user1Uid);
      final result = await repo.updateProfile(fullName: '   ');

      expect(result.isFailure, true);
      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(result.failureOrNull!.message, 'Full name cannot be empty.');
    });

    test('rejects updateProfile when phone is blank whitespace', () async {
      final repo = createRepo(user1Uid);
      final result = await repo.updateProfile(phone: '   ');

      expect(result.isFailure, true);
      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(result.failureOrNull!.message, 'Phone number cannot be empty.');
    });

    test('UpdateProfile use case forwards call to repository', () async {
      final repo = createRepo(user1Uid);
      final useCase = UpdateProfile(repo);
      final result = await useCase(fullName: 'Alice Updated');

      expect(result.isSuccess, true);
      expect(result.dataOrNull!.fullName, 'Alice Updated');
    });
  });
}
