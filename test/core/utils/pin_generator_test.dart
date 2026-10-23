import 'package:flutter_test/flutter_test.dart';
import 'package:changa_app/core/utils/pin_generator.dart';

void main() {
  group('PinGenerator Tests', () {
    test('generates a PIN of the default length (6)', () {
      final pin = PinGenerator.generate();
      expect(pin.length, 6);
    });

    test('generates a PIN of a custom length', () {
      final pin = PinGenerator.generate(length: 8);
      expect(pin.length, 8);
    });

    test('does not contain ambiguous characters (O, 0, I, 1)', () {
      // Generate a long PIN to thoroughly test the character pool
      final pin = PinGenerator.generate(length: 100);

      expect(pin.contains('O'), isFalse);
      expect(pin.contains('0'), isFalse);
      expect(pin.contains('I'), isFalse);
      expect(pin.contains('1'), isFalse);
    });

    test('generates reasonably unique PINs', () {
      final pin1 = PinGenerator.generate();
      final pin2 = PinGenerator.generate();

      expect(pin1, isNot(equals(pin2)));
    });
  });
}
