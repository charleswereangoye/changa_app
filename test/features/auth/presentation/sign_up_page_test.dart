import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:changa_app/features/auth/presentation/pages/sign_up_page.dart';

void main() {
  testWidgets(
    'SignUpPage renders heading, 4 inputs, terms, buttons, and links',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignUpPage()));

      // Verify header
      expect(find.text('Create your account'), findsOneWidget);
      expect(find.text('Join your household in minutes'), findsOneWidget);

      // Verify 4 input labels
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Phone Number'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);

      // Verify terms text
      expect(
        find.text('By continuing you agree to our Terms & Privacy Policy.'),
        findsOneWidget,
      );

      // Verify buttons
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('or continue with'), findsOneWidget);
      expect(find.text('Google'), findsOneWidget);
      expect(find.text('Apple'), findsOneWidget);
      expect(find.textContaining('Log In'), findsOneWidget);
    },
  );
}
