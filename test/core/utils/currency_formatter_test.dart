// Owner: C - Person C (Expenses, Dashboard, Documentation)
// Description: Unit tests for CurrencyFormatter

import 'package:changa_app/core/utils/currency_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CurrencyFormatter', () {
    test('formats thousands with a comma', () {
      expect(CurrencyFormatter.format(24000), 'RWF 24,000');
    });

    test('formats zero', () {
      expect(CurrencyFormatter.format(0), 'RWF 0');
    });

    test('formats millions', () {
      expect(CurrencyFormatter.format(1000000), 'RWF 1,000,000');
    });

    test('keeps the minus sign in front of RWF', () {
      expect(CurrencyFormatter.format(-500), '-RWF 500');
    });
  });
}
