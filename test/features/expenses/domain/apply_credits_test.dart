// Owner: C - Person C (Expenses, Dashboard, Documentation)
// Description: Unit tests for ApplyCredits

import 'package:changa_app/features/expenses/domain/logic/apply_credits.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApplyCredits', () {
    test('uses all credits when the share is bigger', () {
      final r = ApplyCredits.apply(share: 4000, creditBalance: 340);
      expect(r.creditsUsed, 340);
      expect(r.amountDue, 600);
    });

    test('credits greater than the share cover it fully', () {
      final r = ApplyCredits.apply(share: 2000, creditBalance: 340);
      expect(r.creditsUsed, 200);
      expect(r.amountDue, 0);
    });

    test('credits exactly equal to the share leave nothing to pay', () {
      final r = ApplyCredits.apply(share: 1000, creditBalance: 100);
      expect(r.creditsUsed, 100);
      expect(r.amountDue, 0);
    });

    test('zero credits changes nothing', () {
      final r = ApplyCredits.apply(share: 4000, creditBalance: 0);
      expect(r.creditsUsed, 0);
      expect(r.amountDue, 4000);
    });

    test('4,005 RWF with 1,000 credits leaves the odd 5 RWF', () {
      final r = ApplyCredits.apply(share: 4005, creditBalance: 1000);
      expect(r.creditsUsed, 400);
      expect(r.amountDue, 5);
    });

    test('a share under 10 RWF uses no credits', () {
      final r = ApplyCredits.apply(share: 9, creditBalance: 50);
      expect(r.creditsUsed, 0);
      expect(r.amountDue, 9);
    });

    test('a negative balance is treated as zero', () {
      final r = ApplyCredits.apply(share: 500, creditBalance: -5);
      expect(r.creditsUsed, 0);
      expect(r.amountDue, 500);
    });
  });
}
