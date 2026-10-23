import 'package:changa_app/core/constants/app_constants.dart';
import 'package:changa_app/core/utils/date_helpers.dart';

typedef RotationSlot = ({DateTime dueDate, String assigneeUid});

abstract final class RotationPlanner {
  /// One slot per week, starting with [startingUid] and walking down
  /// [orderedUids] (ordered by join date), wrapping back to the top.
  static List<RotationSlot> plan({
    required DateTime firstDueDate,
    required String startingUid,
    required List<String> orderedUids,
    int weeks = AppConstants.recurringChoreInstances,
  }) {
    if (orderedUids.isEmpty) {
      throw ArgumentError.value(orderedUids, 'orderedUids', 'Cannot be empty');
    }
    final start = orderedUids.indexOf(startingUid);
    if (start == -1) {
      throw ArgumentError.value(
        startingUid,
        'startingUid',
        'Must be one of orderedUids',
      );
    }

    return List.generate(weeks, (week) {
      return (
        dueDate: DateHelpers.addDays(firstDueDate, week * 7),
        assigneeUid: orderedUids[(start + week) % orderedUids.length],
      );
    });
  }
}
