import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:changa_app/core/error/failures.dart';
import 'package:changa_app/core/error/result.dart';
import 'package:changa_app/features/auth/domain/entities/app_user.dart';
import 'package:changa_app/features/profile/domain/usecases/update_profile.dart';
import 'package:changa_app/features/profile/domain/usecases/watch_user.dart';
import 'package:changa_app/features/profile/presentation/cubit/profile_cubit.dart';

class MockWatchUser extends Mock implements WatchUser {}

class MockUpdateProfile extends Mock implements UpdateProfile {}

void main() {
  late MockWatchUser mockWatchUser;
  late MockUpdateProfile mockUpdateProfile;
  late StreamController<AppUser?> userStreamController;

  final testUser = AppUser(
    uid: 'user_123',
    fullName: 'Clarisse Keza',
    email: 'clarisse@example.com',
    phone: '+250788111222',
    householdId: 'house_abc',
    createdAt: DateTime(2026, 1, 1),
  );

  setUp(() {
    mockWatchUser = MockWatchUser();
    mockUpdateProfile = MockUpdateProfile();
    userStreamController = StreamController<AppUser?>.broadcast();

    when(() => mockWatchUser(any()))
        .thenAnswer((_) => userStreamController.stream);
  });

  tearDown(() {
    userStreamController.close();
  });

  group('ProfileCubit', () {
    test('initial state is ProfileStateInitial', () {
      final cubit = ProfileCubit(
        watchUser: mockWatchUser,
        updateProfile: mockUpdateProfile,
      );
      expect(cubit.state, isA<ProfileStateInitial>());
      cubit.close();
    });

    test('loadProfile does nothing when uid is empty', () {
      final cubit = ProfileCubit(
        watchUser: mockWatchUser,
        updateProfile: mockUpdateProfile,
      );
      cubit.loadProfile('');
      expect(cubit.state, isA<ProfileStateInitial>());
      verifyNever(() => mockWatchUser(any()));
      cubit.close();
    });

    test(
      'loadProfile does NOT emit ProfileStateLoading if watchUser is null',
      () {
        final cubit = ProfileCubit(watchUser: null);
        cubit.loadProfile('user_123');
        // Should remain ProfileStateInitial, NOT stuck in ProfileStateLoading
        expect(cubit.state, isA<ProfileStateInitial>());
        cubit.close();
      },
    );

    blocTest<ProfileCubit, ProfileState>(
      'loadProfile emits [ProfileStateLoading, ProfileStateLoaded] on user data',
      build: () => ProfileCubit(
        watchUser: mockWatchUser,
        updateProfile: mockUpdateProfile,
      ),
      act: (cubit) {
        cubit.loadProfile('user_123');
        userStreamController.add(testUser);
      },
      expect: () => [const ProfileStateLoading(), ProfileStateLoaded(testUser)],
      verify: (_) {
        verify(() => mockWatchUser('user_123')).called(1);
      },
    );

    blocTest<ProfileCubit, ProfileState>(
      'loadProfile emits [ProfileStateLoading, ProfileStateError] when user is null',
      build: () => ProfileCubit(
        watchUser: mockWatchUser,
        updateProfile: mockUpdateProfile,
      ),
      act: (cubit) {
        cubit.loadProfile('user_123');
        userStreamController.add(null);
      },
      expect: () => [
        const ProfileStateLoading(),
        const ProfileStateError('User not found'),
      ],
    );

    blocTest<ProfileCubit, ProfileState>(
      'loadProfile emits [ProfileStateLoading, ProfileStateError] when stream errors',
      build: () => ProfileCubit(
        watchUser: mockWatchUser,
        updateProfile: mockUpdateProfile,
      ),
      act: (cubit) {
        cubit.loadProfile('user_123');
        userStreamController.addError('Network error');
      },
      expect: () => [
        const ProfileStateLoading(),
        const ProfileStateError('Network error'),
      ],
    );

    blocTest<ProfileCubit, ProfileState>(
      'editProfile emits [ProfileStateLoading, ProfileStateLoaded] and returns true on success',
      build: () {
        when(
          () => mockUpdateProfile(
            fullName: any(named: 'fullName'),
            phone: any(named: 'phone'),
          ),
        ).thenAnswer((_) async => Result.success(testUser));
        return ProfileCubit(
          watchUser: mockWatchUser,
          updateProfile: mockUpdateProfile,
        );
      },
      act: (cubit) async {
        final success = await cubit.editProfile(fullName: 'Clarisse Keza');
        expect(success, true);
      },
      expect: () => [const ProfileStateLoading(), ProfileStateLoaded(testUser)],
      verify: (_) {
        verify(() => mockUpdateProfile(fullName: 'Clarisse Keza', phone: null))
            .called(1);
      },
    );

    blocTest<ProfileCubit, ProfileState>(
      'editProfile emits [ProfileStateLoading, ProfileStateError] and returns false on failure',
      build: () {
        when(
          () => mockUpdateProfile(
            fullName: any(named: 'fullName'),
            phone: any(named: 'phone'),
          ),
        ).thenAnswer(
          (_) async => Result.failure(
            const ValidationFailure('Full name cannot be empty.'),
          ),
        );
        return ProfileCubit(
          watchUser: mockWatchUser,
          updateProfile: mockUpdateProfile,
        );
      },
      act: (cubit) async {
        final success = await cubit.editProfile(fullName: '   ');
        expect(success, false);
      },
      expect: () => [
        const ProfileStateLoading(),
        const ProfileStateError('Full name cannot be empty.'),
      ],
    );
  });
}
