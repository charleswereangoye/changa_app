import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:changa_app/core/error/result.dart';
import 'package:changa_app/features/auth/presentation/cubit/forgot_password_cubit.dart';
import 'package:changa_app/features/auth/presentation/pages/forgot_password_page.dart';

import '../../../helpers/mocks.dart';

void main() {
  group('ForgotPasswordPage Widget Tests', () {
    late MockSendPasswordReset mockSendPasswordReset;
    late ForgotPasswordCubit cubit;

    setUp(() {
      mockSendPasswordReset = MockSendPasswordReset();
      cubit = ForgotPasswordCubit(sendPasswordReset: mockSendPasswordReset);
    });

    tearDown(() {
      cubit.close();
    });

    testWidgets('renders reset password form elements', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: ForgotPasswordPage(cubit: cubit)),
      );

      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Send Reset Link'), findsOneWidget);
    });

    testWidgets('submitting empty shows validation error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: ForgotPasswordPage(cubit: cubit)),
      );

      await tester.tap(find.text('Send Reset Link'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your email address.'), findsOneWidget);
      verifyNever(() => mockSendPasswordReset.call(any()));
    });

    testWidgets('entering email and submitting displays success UI', (
      tester,
    ) async {
      when(() => mockSendPasswordReset.call(any()))
          .thenAnswer((_) async => Result.success(null));

      await tester.pumpWidget(
        MaterialApp(home: ForgotPasswordPage(cubit: cubit)),
      );

      await tester.enterText(find.byType(TextFormField), 'student@school.edu');
      await tester.tap(find.text('Send Reset Link'));
      await tester.pumpAndSettle();

      expect(find.text('Check your inbox'), findsOneWidget);
      expect(find.text('Back to Login'), findsOneWidget);
    });
  });
}
