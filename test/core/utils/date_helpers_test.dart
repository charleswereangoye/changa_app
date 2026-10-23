import 'package:flutter_test/flutter_test.dart';

import 'package:changa/core/utils/date_helpers.dart';
import 'package:changa/features/chores/domain/entities/chore.dart';

Chore _chore(DateTime due, {ChoreStatus status = ChoreStatus.pending}) {
  return Chore(
    id: 'c1',
    title: 'Dishes',
    difficulty: ChoreDifficulty.easy,
    assignedToUid: 'u1',
    dueDate: due,
    status: status,
    createdByUid: 'u1',
    createdAt: DateTime(2026, 10, 1),
  );
}

void main() {
  group('startOfDay / endOfDay', () {
    test('strip and fill the time of day', () {
      final d = DateTime(2026, 10, 14, 9, 30, 15);
      expect(DateHelpers.startOfDay(d), DateTime(2026, 10, 14));
      expect(DateHelpers.endOfDay(d), DateTime(2026, 10, 14, 23, 59, 59, 999));
    });
  });

  group('isSameDay', () {
    test('ignores the time', () {
      expect(
        DateHelpers.isSameDay(
          DateTime(2026, 10, 14, 0, 1),
          DateTime(2026, 10, 14, 23, 59),
        ),
        isTrue,
      );
    });

    test('same day number in another month is a different day', () {
      expect(
        DateHelpers.isSameDay(DateTime(2026, 10, 14), DateTime(2026, 11, 14)),
        isFalse,
      );
    });
  });

  group('addDays', () {
    test('crosses a month end', () {
      expect(
        DateHelpers.addDays(DateTime(2026, 10, 31), 1),
        DateTime(2026, 11, 1),
      );
    });

    test('crosses a year end', () {
      expect(
        DateHelpers.addDays(DateTime(2026, 12, 31), 1),
        DateTime(2027, 1, 1),
      );
    });

    test('knows 2028 is a leap year', () {
      expect(
        DateHelpers.addDays(DateTime(2028, 2, 28), 1),
        DateTime(2028, 2, 29),
      );
      expect(
        DateHelpers.addDays(DateTime(2028, 2, 28), 2),
        DateTime(2028, 3, 1),
      );
    });

    test('knows 2027 is not', () {
      expect(
        DateHelpers.addDays(DateTime(2027, 2, 28), 1),
        DateTime(2027, 3, 1),
      );
    });

    test('goes backwards too', () {
      expect(
        DateHelpers.addDays(DateTime(2026, 11, 1), -1),
        DateTime(2026, 10, 31),
      );
    });
  });

  group('weekDays', () {
    test('starts on Monday', () {
      final week = DateHelpers.weekDays(DateTime(2026, 10, 14, 15, 0));
      expect(week.length, 7);
      expect(week.first, DateTime(2026, 10, 12));
      expect(week.first.weekday, DateTime.monday);
      expect(week.last, DateTime(2026, 10, 18));
    });

    test('a Sunday belongs to the week that is ending', () {
      final week = DateHelpers.weekDays(DateTime(2026, 10, 18));
      expect(week.first, DateTime(2026, 10, 12));
    });

    test('a Monday starts its own week', () {
      final week = DateHelpers.weekDays(DateTime(2026, 10, 12));
      expect(week.first, DateTime(2026, 10, 12));
    });

    test('runs across a month end', () {
      final week = DateHelpers.weekDays(DateTime(2026, 10, 28));
      expect(week.first, DateTime(2026, 10, 26));
      expect(week.last, DateTime(2026, 11, 1));
    });
  });

  group('dayLabel', () {
    test('reads like the roster tab', () {
      expect(DateHelpers.dayLabel(DateTime(2026, 10, 12)), 'Mon 12');
      expect(DateHelpers.dayLabel(DateTime(2026, 10, 18)), 'Sun 18');
    });
  });

  group('isMissed', () {
    final now = DateTime(2026, 10, 23, 14, 0);

    test('pending and due yesterday is missed', () {
      expect(DateHelpers.isMissed(_chore(DateTime(2026, 10, 22)), now), isTrue);
    });

    test('pending and due today is not missed yet', () {
      expect(
        DateHelpers.isMissed(_chore(DateTime(2026, 10, 23)), now),
        isFalse,
      );
    });

    test('pending and due tomorrow is not missed', () {
      expect(
        DateHelpers.isMissed(_chore(DateTime(2026, 10, 24)), now),
        isFalse,
      );
    });

    test('a finished chore is never missed', () {
      final done = _chore(DateTime(2026, 10, 20), status: ChoreStatus.done);
      expect(DateHelpers.isMissed(done, now), isFalse);
    });
  });
}
