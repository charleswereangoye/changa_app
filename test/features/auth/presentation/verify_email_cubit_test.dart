import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:changa_app/core/error/failures.dart';
import 'package:changa_app/core/error/result.dart';
import 'package:changa_app/features/auth/presentation/cubit/verify_email_cubit.dart';

import 'package:changa_app/core/usecase/usecase.dart';

import '../../../helpers/mocks.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(const NoParams());
  });

  group('VerifyEmailCubit', () {
    late MockSendEmailVerification mockSendVerification;
    late MockCheckEmailVerified mockCheckVerified;
    late VerifyEmailCubit cubit;

    setUp(() {
      mockSendVerification = MockSendEmailVerification();
      mockCheckVerified = MockCheckEmailVerified();
      cubit = VerifyEmailCubit(
        sendEmailVerification: mockSendVerification,
        checkEmailVerified: mockCheckVerified,
      );
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state has default flags', () {
      expect(cubit.state.isChecking, isFalse);
      expect(cubit.state.isResending, isFalse);
      expect(cubit.state.isVerified, isFalse);
      expect(cubit.state.resendCooldown, 0);
      expect(cubit.state.canResend, isTrue);
    });

    test('resendVerificationEmail success triggers cooldown', () async {
      when(() => mockSendVerification.call(any()))
          .thenAnswer((_) async => Result.success(null));

      await cubit.resendVerificationEmail();

      expect(cubit.state.resendCooldown, 60);
      expect(cubit.state.message, contains('Verification email sent'));
      verify(() => mockSendVerification.call(any())).called(1);
    });

    test('resendVerificationEmail failure sets errorMessage', () async {
      when(() => mockSendVerification.call(any())).thenAnswer(
        (_) async => Result.failure(const NetworkFailure('Network error.')),
      );

      await cubit.resendVerificationEmail();

      expect(cubit.state.resendCooldown, 0);
      expect(cubit.state.errorMessage, 'Network error.');
    });

    test('checkVerificationStatus returns true when verified', () async {
      when(() => mockCheckVerified.call(any()))
          .thenAnswer((_) async => Result.success(true));

      final result = await cubit.checkVerificationStatus();

      expect(result, isTrue);
      expect(cubit.state.isVerified, isTrue);
      expect(cubit.state.errorMessage, isNull);
    });

    test('checkVerificationStatus returns false and sets errorMessage when not verified', () async {
      when(() => mockCheckVerified.call(any()))
          .thenAnswer((_) async => Result.success(false));

      final result = await cubit.checkVerificationStatus();

      expect(result, isFalse);
      expect(cubit.state.isVerified, isFalse);
      expect(cubit.state.errorMessage, contains('not verified yet'));
    });
  });
}
