import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:changa_app/core/widgets/pin_input.dart';

void main() {
  group('PinInput Tests', () {
    testWidgets('typing 6 digits calls onCompleted', (
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

      final textFields = find.byType(TextField);
      for (int i = 0; i < 6; i++) {
        await tester.enterText(textFields.at(i), i.toString());
      }
      await tester.pump();

      expect(completedPin, '012345');
    });

    testWidgets('correcting a filled box keeps the other digits', (
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

      final textFields = find.byType(TextField);

      // Type 1, 2, 3, 4, 5 in the first five boxes
      await tester.enterText(textFields.at(0), '1');
      await tester.enterText(textFields.at(1), '2');
      await tester.enterText(textFields.at(2), '3');
      await tester.enterText(textFields.at(3), '4');
      await tester.enterText(textFields.at(4), '5');

      await tester.enterText(textFields.at(3), '47');
      await tester.pump();

      // Finish typing the last digit
      await tester.enterText(textFields.at(5), '6');
      await tester.pump();

      // The overwritten '7' should be in the middle, and the rest retained
      expect(completedPin, '123756');
    });

    testWidgets('hasError applies error color to text and borders', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: const ColorScheme.light(error: Colors.red),
          ),
          home: Scaffold(body: PinInput(onCompleted: (_) {}, hasError: true)),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField).first);
      final inputDecoration = textField.decoration as InputDecoration;
      final enabledBorder = inputDecoration.enabledBorder as OutlineInputBorder;

      expect(enabledBorder.borderSide.color, Colors.red);
      expect(textField.style?.color, Colors.red);
    });

    testWidgets('backspace on empty box goes back and clears previous', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: PinInput(onCompleted: (_) {})),
        ),
      );

      final textFields = find.byType(TextField);

      // Type '1' in first box
      await tester.enterText(textFields.at(0), '1');
      await tester.pump();

      // Simulate backspace key press
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();

      // First box should now be empty
      final firstBox = tester.widget<TextField>(textFields.at(0));
      expect(firstBox.controller?.text, isEmpty);
    });
  });
}
