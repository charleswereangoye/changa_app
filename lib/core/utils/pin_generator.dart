import 'dart:math';

class PinGenerator {
  static String generate({int length = 6}) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();

    return Iterable.generate(
      length,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }
}
