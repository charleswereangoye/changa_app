import 'package:changa/features/chores/domain/entities/chore.dart';

/// Calendar-day maths for the roster. Everything works in local time, so a
/// chore due on Tuesday stays a Tuesday whatever the clock says.
abstract final class DateHelpers {
  static const _weekdayNames = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static DateTime startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static DateTime endOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Goes through the constructor so month ends, leap years and clock
  /// changes are handled for us.
  static DateTime addDays(DateTime date, int days) => DateTime(
    date.year,
    date.month,
    date.day + days,
    date.hour,
    date.minute,
    date.second,
    date.millisecond,
  );

  /// The seven days of [date]'s week, Monday first.
  static List<DateTime> weekDays(DateTime date) {
    final monday = addDays(startOfDay(date), -(date.weekday - DateTime.monday));
    return List.generate(7, (i) => addDays(monday, i));
  }

  /// "Mon 14", the label on the roster's day tabs.
  static String dayLabel(DateTime date) =>
      '${_weekdayNames[date.weekday - 1]} ${date.day}';

  /// Still pending and its due day is behind us.
  static bool isMissed(Chore chore, DateTime now) =>
      chore.status == ChoreStatus.pending &&
      startOfDay(chore.dueDate).isBefore(startOfDay(now));
}
