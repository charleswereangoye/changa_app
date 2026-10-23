import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:changa_app/features/auth/presentation/pages/onboarding_page.dart';

void main() {
  group('OnboardingPage Widget Test', () {
    testWidgets('renders first slide with title, Skip and Next buttons', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: OnboardingPage()));

      // Verify Skip button is present
      expect(find.text('Skip'), findsOneWidget);

      // Verify First Slide Title
      expect(find.text('Split expenses,\nnot friendships'), findsOneWidget);

      // Verify Next button is present
      expect(find.text('Next'), findsOneWidget);

      // Verify bottom Sign In prompt
      expect(find.textContaining('Already have an account?'), findsOneWidget);
    });
  });
}
