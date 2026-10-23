import 'package:flutter_test/flutter_test.dart';
import 'package:changa_app/core/utils/validators.dart';

void main() {
  group('Validators.name', () {
    test('returns null for valid names', () {
      expect(Validators.name('Amara Okoye'), isNull);
      expect(Validators.name('Kevin'), isNull);
      expect(Validators.name('Al'), isNull);
    });

    test('returns error for empty or whitespace-only name', () {
      expect(Validators.name(null), 'Please enter your full name.');
      expect(Validators.name(''), 'Please enter your full name.');
      expect(Validators.name('   '), 'Please enter your full name.');
    });

    test('returns error for name shorter than 2 characters', () {
      expect(Validators.name('A'), 'Name must be at least 2 characters.');
    });

    test('returns error for name longer than 50 characters', () {
      final longName = 'A' * 51;
      expect(Validators.name(longName), 'Name must not exceed 50 characters.');
    });
  });

  group('Validators.email', () {
    test('returns null for valid emails', () {
      expect(Validators.email('amara@school.edu'), isNull);
      expect(Validators.email('test.user@gmail.com'), isNull);
      expect(Validators.email('kevin+dev@changa.rw'), isNull);
    });

    test('returns error for empty or whitespace email', () {
      expect(Validators.email(null), 'Please enter your email address.');
      expect(Validators.email(''), 'Please enter your email address.');
      expect(Validators.email('   '), 'Please enter your email address.');
    });

    test('returns error for invalid email patterns', () {
      expect(
        Validators.email('invalid'),
        'Please enter a valid email address.',
      );
      expect(Validators.email('user@'), 'Please enter a valid email address.');
      expect(
        Validators.email('@domain.com'),
        'Please enter a valid email address.',
      );
      expect(
        Validators.email('user@domain'),
        'Please enter a valid email address.',
      );
    });
  });

  group('Validators.phone', () {
    test('returns null for valid Rwandan phone numbers', () {
      expect(Validators.phone('+250 788 123 456'), isNull);
      expect(Validators.phone('+250788123456'), isNull);
      expect(Validators.phone('0788123456'), isNull);
      expect(Validators.phone('0721234567'), isNull);
      expect(Validators.phone('0731234567'), isNull);
      expect(Validators.phone('0791234567'), isNull);
    });

    test('returns error for empty or invalid phone numbers', () {
      expect(Validators.phone(null), 'Please enter your phone number.');
      expect(Validators.phone(''), 'Please enter your phone number.');
      expect(
        Validators.phone('12345'),
        contains('Please enter a valid phone number'),
      );
      expect(
        Validators.phone('0701234567'),
        contains('Please enter a valid phone number'),
      );
    });
  });

  group('Validators.password', () {
    test(
      'returns null for valid password with >=8 chars, letter, and number',
      () {
        expect(Validators.password('Password123'), isNull);
        expect(Validators.password('changa2026'), isNull);
      },
    );

    test('returns error for empty or short password', () {
      expect(Validators.password(null), 'Please create a password.');
      expect(Validators.password(''), 'Please create a password.');
      expect(
        Validators.password('pass1'),
        'Password must be at least 8 characters.',
      );
    });

    test('returns error when letters or numbers are missing', () {
      expect(
        Validators.password('abcdefgh'),
        'Password must contain at least one letter and one number.',
      );
      expect(
        Validators.password('12345678'),
        'Password must contain at least one letter and one number.',
      );
    });
  });

  group('Validators.pin', () {
    test('returns null for valid 6-digit PIN', () {
      expect(Validators.pin('482916'), isNull);
      expect(Validators.pin('100000'), isNull);
    });

    test('returns error for invalid PIN', () {
      expect(Validators.pin(null), 'Please enter the 6-digit PIN.');
      expect(Validators.pin('12345'), 'PIN must be exactly 6 digits.');
      expect(Validators.pin('1234567'), 'PIN must be exactly 6 digits.');
      expect(Validators.pin('abcdef'), 'PIN must be exactly 6 digits.');
    });
  });

  group('Validators.amount', () {
    test('returns null for valid amounts', () {
      expect(Validators.amount('24000'), isNull);
      expect(Validators.amount('24,000'), isNull);
      expect(Validators.amount('100000000'), isNull);
    });

    test('returns error for 0, negative, or excessive amounts', () {
      expect(Validators.amount(null), 'Please enter an amount.');
      expect(Validators.amount('0'), 'Amount must be greater than 0.');
      expect(Validators.amount('-500'), 'Amount must be greater than 0.');
      expect(
        Validators.amount('100000001'),
        'Amount must not exceed 100,000,000 RWF.',
      );
    });
  });
}
