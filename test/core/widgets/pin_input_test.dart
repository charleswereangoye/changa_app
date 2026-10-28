import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:changa_app/core/widgets/pin_input.dart';

void main() {
  group('PinInput Tests', () {
    testWidgets('renders 6 input boxes', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: PinInput(onCompleted: (_) {})),
        ),
      );

      expect(find.byType(TextField), findsNWidgets(6));
    });

    testWidgets('distributes pasted text and triggers onCompleted', (
      WidgetTester tester,
    ) async {
      String? completedPin;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PinInput(onCompleted: (pin) => completedPin = pin),
          ),
        ),
      );

      // Simulate a user pasting '123456' into the first box
      await tester.enterText(find.byType(TextField).first, '123456');
      await tester.pump();

      expect(completedPin, '123456');
    });
  });
}
