import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:changa_app/core/error/failures.dart';
import 'package:changa_app/core/error/result.dart';
import 'package:changa_app/features/auth/domain/entities/app_user.dart';
import 'package:changa_app/features/auth/domain/usecases/sign_in_with_email.dart';
import 'package:changa_app/features/auth/presentation/cubit/login_cubit.dart';

import 'package:changa_app/core/usecase/usecase.dart';

import '../../../helpers/mocks.dart';

class FakeSignInWithEmailParams extends Fake implements SignInWithEmailParams {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeSignInWithEmailParams());
    registerFallbackValue(const NoParams());
  });

  group('LoginCubit', () {
    late MockSignInWithEmail mockSignInWithEmail;
    late MockSignInWithGoogle mockSignInWithGoogle;
    late LoginCubit cubit;

    setUp(() {
      mockSignInWithEmail = MockSignInWithEmail();
      mockSignInWithGoogle = MockSignInWithGoogle();
      cubit = LoginCubit(
        signInWithEmail: mockSignInWithEmail,
        signInWithGoogle: mockSignInWithGoogle,
      );
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state has correct default values', () {
      expect(cubit.state.status, LoginStatus.initial);
      expect(cubit.state.isPasswordVisible, isFalse);
      expect(cubit.state.errorMessage, isNull);
    });

    test('togglePasswordVisibility toggles isPasswordVisible', () {
      cubit.togglePasswordVisibility();
      expect(cubit.state.isPasswordVisible, isTrue);

      cubit.togglePasswordVisibility();
      expect(cubit.state.isPasswordVisible, isFalse);
    });

    test(
      'login with empty fields emits failure status with error message',
      () async {
        await cubit.login(email: '', password: '');
        expect(cubit.state.status, LoginStatus.failure);
        expect(cubit.state.errorMessage, isNotNull);
        verifyNever(() => mockSignInWithEmail.call(any()));
      },
    );

    test('login with valid credentials emits success status', () async {
      when(() => mockSignInWithEmail.call(any())).thenAnswer(
        (_) async => Result.success(
          AppUser(
            uid: 'uid-123',
            fullName: 'Amara',
            email: 'test@school.edu',
            phone: '+250 788 123 456',
            createdAt: DateTime.now(),
          ),
        ),
      );

      await cubit.login(email: 'test@school.edu', password: 'password123');

      expect(cubit.state.status, LoginStatus.success);
      verify(() => mockSignInWithEmail.call(any())).called(1);
    });

    test('login with invalid credentials emits failure with message', () async {
      when(() => mockSignInWithEmail.call(any())).thenAnswer(
        (_) async =>
            Result.failure(const AuthFailure('Invalid email or password.')),
      );

      await cubit.login(email: 'test@school.edu', password: 'wrongpassword');

      expect(cubit.state.status, LoginStatus.failure);
      expect(cubit.state.errorMessage, 'Invalid email or password.');
    });

    test('loginWithGoogle emits success on valid response', () async {
      when(() => mockSignInWithGoogle.call(any())).thenAnswer(
        (_) async => Result.success(
          AppUser(
            uid: 'uid-google',
            fullName: 'Google User',
            email: 'google@school.edu',
            phone: '',
            createdAt: DateTime.now(),
          ),
        ),
      );

      await cubit.loginWithGoogle();
      expect(cubit.state.status, LoginStatus.success);
    });
  });
}
