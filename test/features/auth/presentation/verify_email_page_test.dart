import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:changa_app/core/error/result.dart';
import 'package:changa_app/core/usecase/usecase.dart';
import 'package:changa_app/features/auth/domain/entities/app_user.dart';
import 'package:changa_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:changa_app/features/auth/presentation/cubit/verify_email_cubit.dart';
import 'package:changa_app/features/auth/presentation/pages/verify_email_page.dart';

import '../../../helpers/mocks.dart';

class FakeAppUser extends Fake implements AppUser {}

void main() {
  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(FakeAppUser());
  });

  group('VerifyEmailPage Widget Tests', () {
    late MockSendEmailVerification mockSendVerification;
    late MockCheckEmailVerified mockCheckVerified;
    late MockAuthRepository mockAuthRepository;
    late VerifyEmailCubit verifyEmailCubit;
    late AuthCubit authCubit;

    final testUser = AppUser(
      uid: 'user-1',
      fullName: 'Amara Okoye',
      email: 'amara@school.edu',
      phone: '+250 788 123 456',
      createdAt: DateTime.now(),
    );

    setUp(() {
      mockSendVerification = MockSendEmailVerification();
      mockCheckVerified = MockCheckEmailVerified();
      mockAuthRepository = MockAuthRepository();

      when(() => mockAuthRepository.authStateChanges)
          .thenAnswer((_) => Stream.value(testUser));
      when(() => mockAuthRepository.currentUser).thenReturn(testUser);
      when(() => mockAuthRepository.updateCurrentUser(any())).thenReturn(null);

      verifyEmailCubit = VerifyEmailCubit(
        sendEmailVerification: mockSendVerification,
        checkEmailVerified: mockCheckVerified,
      );
      authCubit = AuthCubit(authRepository: mockAuthRepository);
      authCubit.updateUser(testUser);
    });

    tearDown(() {
      verifyEmailCubit.close();
      authCubit.close();
    });

    testWidgets('renders all email verification screen components', (
      tester,
    ) async {
      await tester.pumpWidget(
        BlocProvider<AuthCubit>.value(
          value: authCubit,
          child: MaterialApp(home: VerifyEmailPage(cubit: verifyEmailCubit)),
        ),
      );
      await tester.pump();

      expect(find.text('Verify your email'), findsOneWidget);
      expect(find.textContaining('amara@school.edu'), findsOneWidget);
      expect(find.text("I've Verified"), findsOneWidget);
      expect(find.text('Resend Verification Email'), findsOneWidget);
      expect(find.text('Log Out / Use Different Account'), findsOneWidget);
    });

    testWidgets('tapping Resend Verification Email invokes usecase', (
      tester,
    ) async {
      when(() => mockSendVerification.call(any()))
          .thenAnswer((_) async => Result.success(null));

      await tester.pumpWidget(
        BlocProvider<AuthCubit>.value(
          value: authCubit,
          child: MaterialApp(home: VerifyEmailPage(cubit: verifyEmailCubit)),
        ),
      );

      await tester.tap(find.text('Resend Verification Email'));
      await tester.pump();

      verify(() => mockSendVerification.call(any())).called(1);
    });

    testWidgets("tapping I've Verified checks status", (tester) async {
      when(() => mockCheckVerified.call(any()))
          .thenAnswer((_) async => Result.success(false));

      await tester.pumpWidget(
        BlocProvider<AuthCubit>.value(
          value: authCubit,
          child: MaterialApp(home: VerifyEmailPage(cubit: verifyEmailCubit)),
        ),
      );

      await tester.tap(find.text("I've Verified"));
      await tester.pumpAndSettle();

      verify(() => mockCheckVerified.call(any())).called(1);
      expect(find.textContaining('not verified yet'), findsOneWidget);
    });
  });
}
