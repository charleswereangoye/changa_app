import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:changa_app/features/auth/presentation/pages/login_page.dart';

void main() {
  testWidgets('LoginPage renders heading, inputs, buttons, and links', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

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
    expect(find.text('Apple'), findsOneWidget);
    expect(find.textContaining('Sign Up'), findsOneWidget);
  });
}
