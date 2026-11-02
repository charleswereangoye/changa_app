import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:changa_app/core/error/result.dart';
import 'package:changa_app/features/auth/domain/entities/app_user.dart';
import 'package:changa_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:changa_app/features/auth/presentation/cubit/auth_cubit.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late StreamController<AppUser?> authStateStreamController;

  final testUser = AppUser(
    uid: 'test_uid_123',
    fullName: 'David Rugamba',
    email: 'david@example.com',
    phone: '+250788123456',
    householdId: 'house_xyz',
    createdAt: DateTime(2026, 1, 1),
  );

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    authStateStreamController = StreamController<AppUser?>.broadcast();
    when(() => mockAuthRepository.authStateChanges)
        .thenAnswer((_) => authStateStreamController.stream);
    when(() => mockAuthRepository.currentUser).thenReturn(null);
  });

  tearDown(() {
    authStateStreamController.close();
  });

  group('AuthCubit', () {
    test('initial state begins with AuthStateLoading when initialized', () {
      final cubit = AuthCubit(authRepository: mockAuthRepository);
      expect(cubit.state, isA<AuthStateLoading>());
      cubit.close();
    });

    blocTest<AuthCubit, AuthState>(
      'emits Authenticated with householdId when user signs in',
      build: () => AuthCubit(authRepository: mockAuthRepository),
      act: (_) => authStateStreamController.add(testUser),
      expect: () => [Authenticated(testUser)],
      verify: (cubit) {
        expect(cubit.state.isAuthenticated, true);
        expect(cubit.state.user?.householdId, 'house_xyz');
      },
    );

    blocTest<AuthCubit, AuthState>(
      'emits Unauthenticated when authStateChanges emits null',
      build: () => AuthCubit(authRepository: mockAuthRepository),
      act: (_) => authStateStreamController.add(null),
      expect: () => [const Unauthenticated()],
      verify: (cubit) {
        expect(cubit.state.isAuthenticated, false);
        expect(cubit.state.user, isNull);
      },
    );

    blocTest<AuthCubit, AuthState>(
      'calls signOut on repository when cubit.signOut is invoked',
      build: () {
        when(() => mockAuthRepository.signOut())
            .thenAnswer((_) async => Result.success(null));
        return AuthCubit(authRepository: mockAuthRepository);
      },
      act: (cubit) async => cubit.signOut(),
      verify: (_) {
        verify(() => mockAuthRepository.signOut()).called(1);
      },
    );
  });
}
