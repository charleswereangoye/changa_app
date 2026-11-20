import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:changa_app/core/error/result.dart';
import 'package:changa_app/core/router/route_names.dart';
import 'package:changa_app/features/auth/domain/entities/app_user.dart';
import 'package:changa_app/features/auth/domain/usecases/sign_in_with_email.dart';
import 'package:changa_app/features/auth/presentation/cubit/login_cubit.dart';
import 'package:changa_app/features/auth/presentation/pages/login_page.dart';

import '../../../helpers/mocks.dart';

class FakeSignInWithEmailParams extends Fake implements SignInWithEmailParams {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeSignInWithEmailParams());
  });

  GoRouter createTestRouter() {
    return GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          name: RouteNames.login,
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: '/home/dashboard',
          name: RouteNames.dashboard,
          builder: (context, state) => const Scaffold(body: Text('Dashboard')),
        ),
        GoRoute(
          path: '/sign-up',
          name: RouteNames.signUp,
          builder: (context, state) => const Scaffold(body: Text('SignUp')),
        ),
        GoRoute(
          path: '/forgot-password',
          name: RouteNames.forgotPassword,
          builder: (context, state) =>
              const Scaffold(body: Text('ForgotPassword')),
        ),
      ],
    );
  }

  group('LoginPage Widget Tests', () {
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

    testWidgets('LoginPage renders heading, inputs, buttons, and links', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp.router(routerConfig: createTestRouter()),
      );

      // Verify header
      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Log in to your account to continue'), findsOneWidget);

      // Verify fields
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);

      // Verify actions
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.text('Log In'), findsOneWidget);
      expect(find.text('or continue with'), findsOneWidget);
      expect(find.text('Google'), findsOneWidget);
      expect(find.text('Apple'), findsNothing);
      expect(find.textContaining('Sign Up'), findsOneWidget);
    });

    testWidgets('submitting empty form displays validation errors', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp.router(routerConfig: createTestRouter()),
      );

      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your email address.'), findsOneWidget);
      expect(find.text('Please enter your password.'), findsOneWidget);
    });

    testWidgets(
      'submitting valid credentials calls login on cubit and navigates',
      (WidgetTester tester) async {
        when(() => mockSignInWithEmail.call(any())).thenAnswer(
          (_) async => Result.success(
            AppUser(
              uid: 'u1',
              fullName: 'Amara',
              email: 'amara@school.edu',
              phone: '+250 788 123 456',
              createdAt: DateTime.now(),
            ),
          ),
        );

        await tester.pumpWidget(
          MaterialApp.router(routerConfig: createTestRouter()),
        );

        await tester.enterText(
          find.byType(TextFormField).at(0),
          'amara@school.edu',
        );
        await tester.enterText(find.byType(TextFormField).at(1), 'password123');

        await tester.tap(find.text('Log In'));
        await tester.pumpAndSettle();

        expect(find.text('Dashboard'), findsOneWidget);
      },
    );
  });
}
