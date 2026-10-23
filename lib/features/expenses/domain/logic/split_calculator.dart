// Owner: C - Person C (Expenses, Dashboard, Documentation)
// Description: Pure domain logic for equal, percentage, and exact splits

import 'package:changa_app/features/expenses/domain/entities/split_type.dart';

/// Thrown for input that can't be split. The AddExpense use case turns this
/// into a ValidationFailure, so this file doesn't depend on core/error.
class SplitInputException implements Exception {
  const SplitInputException(this.message);

  final String message;

  @override
  String toString() => 'SplitInputException: $message';
}

abstract final class SplitCalculator {
  /// Returns uid -> share in whole RWF. The shares always add up to [total].
  /// The payer is included here; leaving the payer out of the debts is done
  /// later, when the debts are created.
  static Map<String, int> calculate({
    required int total,
    required List<String> participants,
    required SplitType splitType,
    Map<String, int> weights = const {},
  }) {
    if (total <= 0) {
      throw const SplitInputException('Amount must be greater than 0.');
    }
    if (participants.isEmpty) {
      throw const SplitInputException('Choose at least one person.');
    }
    if (participants.toSet().length != participants.length) {
      throw const SplitInputException('A person is listed twice.');
    }
    return switch (splitType) {
      SplitType.equal => _equal(total, participants),
      SplitType.percent => _percent(total, participants, weights),
      SplitType.exact => _exact(total, participants, weights),
    };
  }

  static Map<String, int> _equal(int total, List<String> participants) {
    final n = participants.length;
    final base = total ~/ n;
    final remainder = total % n;
    return {
      for (var i = 0; i < n; i++)
        participants[i]: base + (i < remainder ? 1 : 0),
    };
  }

  static Map<String, int> _percent(
    int total,
    List<String> participants,
    Map<String, int> weights,
  ) {
    final percents = _weightsFor(participants, weights);
    if (percents.fold(0, (a, b) => a + b) != 100) {
      throw const SplitInputException('Percentages must add up to 100.');
    }
    final shares = <String, int>{};
    var assigned = 0;
    for (var i = 0; i < participants.length - 1; i++) {
      final share = (total * percents[i] + 50) ~/ 100; // rounded
      shares[participants[i]] = share;
      assigned += share;
    }
    final last = total - assigned; // the last person takes what is left
    if (last < 0) {
      throw const SplitInputException(
        'These percentages cannot be applied to such a small amount.',
      );
    }
    shares[participants.last] = last;
    return shares;
  }

  static Map<String, int> _exact(
    int total,
    List<String> participants,
    Map<String, int> weights,
  ) {
    final amounts = _weightsFor(participants, weights);
    final sum = amounts.fold(0, (a, b) => a + b);
    if (sum != total) {
      throw SplitInputException(
        'Amounts must add up to the total ($sum of $total).',
      );
    }
    return {
      for (var i = 0; i < participants.length; i++) participants[i]: amounts[i],
    };
  }

  static List<int> _weightsFor(
    List<String> participants,
    Map<String, int> weights,
  ) {
    return [
      for (final uid in participants)
        switch (weights[uid]) {
          null => throw SplitInputException('Missing an amount for $uid.'),
          final w when w < 0 => throw const SplitInputException(
            'Amounts cannot be negative.',
          ),
          final w => w,
        },
    ];
  }
}
