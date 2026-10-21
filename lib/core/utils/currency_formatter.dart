// Owner: C - Person C (Expenses, Dashboard, Documentation)
// Description: Currency formatting for RWF

import 'package:intl/intl.dart';

/// Formats whole-RWF amounts, e.g. 24000 -> "RWF 24,000".
/// RWF has no decimals anywhere in Changa.
abstract final class CurrencyFormatter {
  static final NumberFormat _number = NumberFormat('#,##0', 'en_US');

  static String format(int amount) {
    final sign = amount < 0 ? '-' : '';
    return '${sign}RWF ${_number.format(amount.abs())}';
  }
}
