// Owner: C - Person C (Expenses, Dashboard, Documentation)
// Description: Unit tests for SplitCalculator (equal, percent, exact)

import 'package:changa_app/features/expenses/domain/entities/split_type.dart';
import 'package:changa_app/features/expenses/domain/logic/split_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const a = 'a';
  const b = 'b';
  const c = 'c';

  Map<String, int> split(
    int total,
    List<String> who,
    SplitType type, [
    Map<String, int> weights = const {},
  ]) => SplitCalculator.calculate(
    total: total,
    participants: who,
    splitType: type,
    weights: weights,
  );

  int sum(Map<String, int> m) => m.values.fold(0, (x, y) => x + y);

  group('equal split', () {
    test('10,000 between 3: first person pays the extra RWF', () {
      expect(split(10000, [a, b, c], SplitType.equal), {
        a: 3334,
        b: 3333,
        c: 3333,
      });
    });

    test('100 between 3', () {
      expect(split(100, [a, b, c], SplitType.equal), {a: 34, b: 33, c: 33});
    });

    test('the order decides who pays the extra RWF', () {
      expect(split(100, [c, a, b], SplitType.equal), {c: 34, a: 33, b: 33});
    });

    test('one participant pays everything', () {
      expect(split(5000, [a], SplitType.equal), {a: 5000});
    });

    test('shares always add up to the total', () {
      for (final total in [1, 7, 99, 100, 4005, 24000, 99999]) {
        for (final n in [1, 2, 3, 4, 7]) {
          final who = [for (var i = 0; i < n; i++) 'u$i'];
          expect(sum(split(total, who, SplitType.equal)), total);
        }
      }
    });
  });

  group('percent split', () {
    test('33/33/34 of 100', () {
      expect(split(100, [a, b, c], SplitType.percent, {a: 33, b: 33, c: 34}), {
        a: 33,
        b: 33,
        c: 34,
      });
    });

    test('the last person takes the rounding leftover', () {
      final r = split(
        1000,
        [a, b, c],
        SplitType.percent,
        {a: 33, b: 33, c: 34},
      );
      expect(r, {a: 330, b: 330, c: 340});
      expect(sum(r), 1000);
    });

    test('percentages not adding up to 100 are rejected', () {
      expect(
        () => split(100, [a, b], SplitType.percent, {a: 50, b: 40}),
        throwsA(isA<SplitInputException>()),
      );
    });
  });

  group('exact split', () {
    test('amounts that match the total are accepted', () {
      expect(split(1000, [a, b], SplitType.exact, {a: 700, b: 300}), {
        a: 700,
        b: 300,
      });
    });

    test('amounts that do not match the total are rejected', () {
      expect(
        () => split(1000, [a, b], SplitType.exact, {a: 700, b: 200}),
        throwsA(isA<SplitInputException>()),
      );
    });

    test('a missing amount is rejected', () {
      expect(
        () => split(1000, [a, b], SplitType.exact, {a: 1000}),
        throwsA(isA<SplitInputException>()),
      );
    });
  });

  group('bad input', () {
    test('zero total is rejected', () {
      expect(
        () => split(0, [a], SplitType.equal),
        throwsA(isA<SplitInputException>()),
      );
    });

    test('no participants is rejected', () {
      expect(
        () => split(1000, [], SplitType.equal),
        throwsA(isA<SplitInputException>()),
      );
    });
  });
}
