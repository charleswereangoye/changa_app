import 'package:flutter_test/flutter_test.dart';
import 'package:changa_app/features/auth/presentation/cubit/sign_up_cubit.dart';

void main() {
  group('SignUpCubit', () {
    late SignUpCubit cubit;

    setUp(() {
      cubit = SignUpCubit();
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state has correct default values', () {
      expect(cubit.state.status, SignUpStatus.initial);
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
      'signUp with empty fields emits failure status with error message',
      () async {
        await cubit.signUp(fullName: '', email: '', phone: '', password: '');
        expect(cubit.state.status, SignUpStatus.failure);
        expect(cubit.state.errorMessage, isNotNull);
      },
    );

    test('signUp with short password emits failure status', () async {
      await cubit.signUp(
        fullName: 'Amara Okoye',
        email: 'amara@school.edu',
        phone: '+250788123456',
        password: '123',
      );
      expect(cubit.state.status, SignUpStatus.failure);
      expect(
        cubit.state.errorMessage,
        'Password must be at least 6 characters.',
      );
    });

    test('signUp with valid fields emits success status', () async {
      await cubit.signUp(
        fullName: 'Amara Okoye',
        email: 'amara@school.edu',
        phone: '+250788123456',
        password: 'password123',
      );
      expect(cubit.state.status, SignUpStatus.success);
    });

    test('signUpWithGoogle emits success status', () async {
      await cubit.signUpWithGoogle();
      expect(cubit.state.status, SignUpStatus.success);
    });

    test('signUpWithApple emits success status', () async {
      await cubit.signUpWithApple();
      expect(cubit.state.status, SignUpStatus.success);
    });
  });
}
