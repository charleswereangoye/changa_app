// Tests nudge eligibility and the 24-hour cooldown.

import 'package:changa_app/core/constants/app_constants.dart';
import 'package:changa_app/core/error/failures.dart';
import 'package:changa_app/features/debts/domain/entities/debt.dart';
import 'package:changa_app/features/debts/domain/entities/debt_status.dart';
import 'package:changa_app/features/debts/domain/logic/nudge_policy.dart';
import 'package:changa_app/features/debts/domain/logic/settlement_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const policy = NudgePolicy(
    cooldown: Duration(hours: AppConstants.nudgeCooldownHours),
  );

  final now = DateTime.utc(2026, 10, 24, 12);

  SettlementPlan balance({int owedToMe = 6000, int owedByMe = 0}) {
    return SettlementPlan.between(
      debts: [
        Debt(
          id: 'owed-to-me',
          expenseId: 'expense-1',
          debtorUid: 'kevin',
          creditorUid: 'me',
          amount: owedToMe,
          creditsApplied: 0,
          status: DebtStatus.pending,
          createdAt: DateTime.utc(2026, 10, 20),
        ),
        Debt(
          id: 'owed-by-me',
          expenseId: 'expense-2',
          debtorUid: 'me',
          creditorUid: 'kevin',
          amount: owedByMe,
          creditsApplied: 0,
          status: DebtStatus.pending,
          createdAt: DateTime.utc(2026, 10, 20),
        ),
      ],
      meUid: 'me',
      otherUid: 'kevin',
    );
  }

  group('NudgePolicy', () {
    test('the configured cooldown is 24 hours', () {
      expect(policy.cooldown, const Duration(hours: 24));
    });

    test('first nudge is allowed when the recipient owes me', () {
      final failure = policy.check(balance: balance(), now: now);

      expect(failure, isNull);
    });

    test('a second nudge within 24 hours is refused', () {
      final failure = policy.check(
        balance: balance(),
        now: now,
        lastNudgedAt: now.subtract(const Duration(hours: 23)),
      );

      expect(failure, isA<NudgeCooldownFailure>());
    });

    test('a nudge after 25 hours is allowed', () {
      final failure = policy.check(
        balance: balance(),
        now: now,
        lastNudgedAt: now.subtract(const Duration(hours: 25)),
      );

      expect(failure, isNull);
    });

    test('a nudge at exactly 24 hours is allowed', () {
      final failure = policy.check(
        balance: balance(),
        now: now,
        lastNudgedAt: now.subtract(const Duration(hours: 24)),
      );

      expect(failure, isNull);
    });

    test('one second before the cooldown expires is refused', () {
      final failure = policy.check(
        balance: balance(),
        now: now,
        lastNudgedAt: now.subtract(
          const Duration(hours: 23, minutes: 59, seconds: 59),
        ),
      );

      expect(failure, isA<NudgeCooldownFailure>());
    });

    test('a zero net balance cannot be nudged', () {
      final failure = policy.check(
        balance: balance(owedToMe: 6000, owedByMe: 6000),
        now: now,
      );

      expect(failure, isA<ValidationFailure>());
    });

    test('I cannot nudge someone when I owe them overall', () {
      final failure = policy.check(
        balance: balance(owedToMe: 2000, owedByMe: 6000),
        now: now,
      );

      expect(failure, isA<ValidationFailure>());
    });

    test('positive net balance is eligible despite debts both ways', () {
      final failure = policy.check(
        balance: balance(owedToMe: 6000, owedByMe: 2000),
        now: now,
      );

      expect(failure, isNull);
    });

    test('an empty debt history cannot be nudged', () {
      final failure = policy.check(
        balance: SettlementPlan.between(
          debts: [],
          meUid: 'me',
          otherUid: 'kevin',
        ),
        now: now,
      );

      expect(failure, isA<ValidationFailure>());
    });

    test('a future nudge timestamp does not bypass the cooldown', () {
      final failure = policy.check(
        balance: balance(),
        now: now,
        lastNudgedAt: now.add(const Duration(hours: 1)),
      );

      expect(failure, isA<NudgeCooldownFailure>());
    });

    test('zero and negative cooldowns are rejected', () {
      for (final cooldown in [Duration.zero, const Duration(hours: -1)]) {
        final invalidPolicy = NudgePolicy(cooldown: cooldown);

        expect(
          () => invalidPolicy.check(balance: balance(), now: now),
          throwsArgumentError,
        );
      }
    });
  });
}
