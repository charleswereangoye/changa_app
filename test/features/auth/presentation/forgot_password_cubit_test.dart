import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:changa_app/core/error/failures.dart';
import 'package:changa_app/core/error/result.dart';
import 'package:changa_app/features/auth/presentation/cubit/forgot_password_cubit.dart';

import '../../../helpers/mocks.dart';

void main() {
  group('ForgotPasswordCubit', () {
    late MockSendPasswordReset mockSendPasswordReset;
    late ForgotPasswordCubit cubit;

    setUp(() {
      mockSendPasswordReset = MockSendPasswordReset();
      cubit = ForgotPasswordCubit(sendPasswordReset: mockSendPasswordReset);
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is ForgotPasswordStateInitial', () {
      expect(cubit.state, isA<ForgotPasswordStateInitial>());
    });

    test('submitEmail with empty string emits failure', () async {
      await cubit.submitEmail('   ');
      expect(cubit.state, isA<ForgotPasswordFailure>());
      expect(
        (cubit.state as ForgotPasswordFailure).errorMessage,
        'Please enter your email address.',
      );
    });

    test('submitEmail success emits [Loading, Success]', () async {
      when(() => mockSendPasswordReset.call(any()))
          .thenAnswer((_) async => Result.success(null));

      final states = <ForgotPasswordState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.submitEmail('user@school.edu');
      await Future.delayed(Duration.zero);

      expect(states.length, 2);
      expect(states[0], isA<ForgotPasswordLoading>());
      expect(states[1], isA<ForgotPasswordSuccess>());

      verify(() => mockSendPasswordReset.call('user@school.edu')).called(1);
      await subscription.cancel();
    });

    test('submitEmail failure emits [Loading, Failure]', () async {
      when(() => mockSendPasswordReset.call(any())).thenAnswer(
        (_) async => Result.failure(const AuthFailure('No account found.')),
      );

      final states = <ForgotPasswordState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.submitEmail('unknown@school.edu');
      await Future.delayed(Duration.zero);

      expect(states.length, 2);
      expect(states[0], isA<ForgotPasswordLoading>());
      expect(states[1], isA<ForgotPasswordFailure>());
      expect(
        (states[1] as ForgotPasswordFailure).errorMessage,
        'No account found.',
      );

      await subscription.cancel();
    });
  });
}
