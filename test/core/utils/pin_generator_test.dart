import 'package:flutter_test/flutter_test.dart';
import 'package:changa_app/core/utils/pin_generator.dart';

void main() {
  group('PinGenerator Tests', () {
    test('generates exactly a 6-digit numeric string', () {
      final pinString = PinGenerator.generate();
      expect(pinString.length, 6);
      expect(int.tryParse(pinString), isNotNull);
    });

    test('generates a PIN strictly within the 100000 to 999999 range', () {
      final pinString = PinGenerator.generate();
      final pin = int.parse(pinString);
      expect(pin, greaterThanOrEqualTo(100000));
      expect(pin, lessThanOrEqualTo(999999));
    });

    test('generates unique PINs', () {
      final pin1 = PinGenerator.generate();
      final pin2 = PinGenerator.generate();
      expect(pin1, isNot(equals(pin2)));
    });
  });
}
