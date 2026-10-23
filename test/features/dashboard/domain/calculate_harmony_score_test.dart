import 'package:changa_app/features/debts/domain/entities/debt.dart';
import 'package:changa_app/features/debts/domain/entities/debt_status.dart';
import 'package:changa_app/core/enums/settlement_method.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:changa_app/features/chores/domain/entities/chore.dart';
import 'package:changa_app/features/dashboard/domain/entities/harmony_score.dart';
import 'package:changa_app/features/dashboard/domain/logic/calculate_harmony_score.dart';

final _now = DateTime(2026, 10, 23, 12);
const _calculate = CalculateHarmonyScore();

Chore _chore({
  required DateTime due,
  DateTime? completedAt,
  ChoreStatus status = ChoreStatus.pending,
}) {
  return Chore(
    id: 'c-${due.microsecondsSinceEpoch}-${completedAt?.day}',
    title: 'Dishes',
    difficulty: ChoreDifficulty.easy,
    assignedToUid: 'u1',
    dueDate: due,
    status: status,
    completedAt: completedAt,
    createdByUid: 'u1',
    createdAt: DateTime(2026, 10, 1),
  );
}

Chore _doneOn(DateTime due, DateTime completed) =>
    _chore(due: due, completedAt: completed, status: ChoreStatus.done);

Debt _debt({
  required DateTime created,
  DebtStatus status = DebtStatus.pending,
  DateTime? settledAt,
  SettlementMethod? method,
}) {
  return Debt(
    id: 'd-${created.microsecondsSinceEpoch}-${settledAt?.day}',
    householdId: 'h1',
    fromUid: 'u2',
    toUid: 'u1',
    amount: 4000,
    status: status,
    settledMethod: method,
    settledAt: settledAt,
    createdAt: created,
  );
}

void main() {
  group('no data', () {
    test('returns null so the dashboard can show a dash', () {
      expect(_calculate(chores: [], debts: [], now: _now), isNull);
    });

    test('a chore due today and still open is not judged yet', () {
      final score = _calculate(
        chores: [_chore(due: DateTime(2026, 10, 23))],
        debts: [],
        now: _now,
      );
      expect(score, isNull);
    });

    test('chores outside the 14 day window are ignored', () {
      final score = _calculate(
        chores: [_chore(due: DateTime(2026, 10, 1))],
        debts: [],
        now: _now,
      );
      expect(score, isNull);
    });
  });

  group('chores only', () {
    test('everything on time is 100 and thriving', () {
      final score = _calculate(
        chores: [
          _doneOn(DateTime(2026, 10, 20), DateTime(2026, 10, 20, 9)),
          _doneOn(DateTime(2026, 10, 21), DateTime(2026, 10, 19)),
        ],
        debts: [],
        now: _now,
      )!;
      expect(score.value, 100);
      expect(score.tier, HarmonyTier.thriving);
      expect(score.paymentScore, isNull);
    });

    test('a late completion still counts as a chore, but not on time', () {
      final score = _calculate(
        chores: [_doneOn(DateTime(2026, 10, 20), DateTime(2026, 10, 22))],
        debts: [],
        now: _now,
      )!;
      expect(score.value, 0);
      expect(score.tier, HarmonyTier.needsAttention);
    });

    test('a pending chore whose day has passed counts against the house', () {
      final score = _calculate(
        chores: [
          _doneOn(DateTime(2026, 10, 20), DateTime(2026, 10, 20)),
          _chore(due: DateTime(2026, 10, 22)),
        ],
        debts: [],
        now: _now,
      )!;
      expect(score.value, 50);
    });
  });

  group('debts only', () {
    test('settled within 3 days is healthy', () {
      final created = DateTime(2026, 10, 15, 12);
      final score = _calculate(
        chores: [],
        debts: [
          _debt(
            created: created,
            status: DebtStatus.settled,
            settledAt: created.add(const Duration(days: 3)),
            method: SettlementMethod.momo,
          ),
        ],
        now: _now,
      )!;
      expect(score.value, 100);
      expect(score.choreScore, isNull);
    });

    test('settled after exactly 7 days is still healthy, 8 is not', () {
      final created = DateTime(2026, 10, 10, 12);
      final sevenDays = _debt(
        created: created,
        status: DebtStatus.settled,
        settledAt: created.add(const Duration(days: 7)),
        method: SettlementMethod.cash,
      );
      final eightDays = _debt(
        created: created,
        status: DebtStatus.settled,
        settledAt: created.add(const Duration(days: 8)),
        method: SettlementMethod.cash,
      );
      expect(_calculate(chores: [], debts: [sevenDays], now: _now)!.value, 100);
      expect(_calculate(chores: [], debts: [eightDays], now: _now)!.value, 0);
    });

    test('pending for 8 days is not healthy', () {
      final score = _calculate(
        chores: [],
        debts: [_debt(created: DateTime(2026, 10, 15, 12))],
        now: _now,
      )!;
      expect(score.value, 0);
    });

    test('pending for 2 days is still healthy', () {
      final score = _calculate(
        chores: [],
        debts: [_debt(created: DateTime(2026, 10, 21, 12))],
        now: _now,
      )!;
      expect(score.value, 100);
    });

    test('paid by credits counts as healthy however old', () {
      final created = DateTime(2026, 10, 1, 12);
      final score = _calculate(
        chores: [],
        debts: [
          _debt(
            created: created,
            status: DebtStatus.settled,
            settledAt: created.add(const Duration(days: 20)),
            method: SettlementMethod.credits,
          ),
        ],
        now: _now,
      )!;
      expect(score.value, 100);
    });

    test('debts older than 30 days are ignored', () {
      final score = _calculate(
        chores: [],
        debts: [_debt(created: DateTime(2026, 9, 1))],
        now: _now,
      );
      expect(score, isNull);
    });
  });

  group('mixed', () {
    test('2 of 3 chores (67) with 4 of 4 debts (100) rounds to 84', () {
      final score = _calculate(
        chores: [
          _doneOn(DateTime(2026, 10, 20), DateTime(2026, 10, 20)),
          _doneOn(DateTime(2026, 10, 21), DateTime(2026, 10, 21)),
          _chore(due: DateTime(2026, 10, 22)),
        ],
        debts: [
          for (var i = 0; i < 4; i++)
            _debt(created: DateTime(2026, 10, 22, 8 + i)),
        ],
        now: _now,
      )!;
      expect(score.choreScore, 67);
      expect(score.paymentScore, 100);
      expect(score.value, 84);
      expect(score.tier, HarmonyTier.thriving);
    });
  });

  group('tiers', () {
    test('sit on the right side of every boundary', () {
      expect(HarmonyTier.fromValue(0), HarmonyTier.needsAttention);
      expect(HarmonyTier.fromValue(49), HarmonyTier.needsAttention);
      expect(HarmonyTier.fromValue(50), HarmonyTier.steady);
      expect(HarmonyTier.fromValue(79), HarmonyTier.steady);
      expect(HarmonyTier.fromValue(80), HarmonyTier.thriving);
      expect(HarmonyTier.fromValue(100), HarmonyTier.thriving);
    });
  });
}
