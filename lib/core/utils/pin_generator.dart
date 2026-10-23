import 'dart:math';

class PinGenerator {
  static String generate() {
    final random = Random.secure();
    final pin = 100000 + random.nextInt(900000);
    return pin.toString();
  }
}
