import 'package:flutter_test/flutter_test.dart';
import 'package:changa_app/features/auth/presentation/cubit/login_cubit.dart';

void main() {
  group('LoginCubit', () {
    late LoginCubit cubit;

    setUp(() {
      cubit = LoginCubit();
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
      },
    );

    test('login with valid fields emits success status', () async {
      await cubit.login(email: 'test@school.edu', password: 'password123');
      expect(cubit.state.status, LoginStatus.success);
    });

    test('loginWithGoogle emits success status', () async {
      await cubit.loginWithGoogle();
      expect(cubit.state.status, LoginStatus.success);
    });

    test('loginWithApple emits success status', () async {
      await cubit.loginWithApple();
      expect(cubit.state.status, LoginStatus.success);
    });
  });
}
