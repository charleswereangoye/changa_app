import 'package:flutter_test/flutter_test.dart';

import 'package:changa_app/features/chores/domain/logic/rotation_planner.dart';

List<String> _who(List<RotationSlot> slots) =>
    slots.map((s) => s.assigneeUid).toList();

void main() {
  final first = DateTime(2026, 10, 26);

  test('three members over four weeks wraps back to the start', () {
    final slots = RotationPlanner.plan(
      firstDueDate: first,
      startingUid: 'a',
      orderedUids: ['a', 'b', 'c'],
    );
    expect(_who(slots), ['a', 'b', 'c', 'a']);
  });

  test('a single member takes every week', () {
    final slots = RotationPlanner.plan(
      firstDueDate: first,
      startingUid: 'a',
      orderedUids: ['a'],
    );
    expect(_who(slots), ['a', 'a', 'a', 'a']);
  });

  test('starting in the middle of the list carries on from there', () {
    final slots = RotationPlanner.plan(
      firstDueDate: first,
      startingUid: 'b',
      orderedUids: ['a', 'b', 'c'],
    );
    expect(_who(slots), ['b', 'c', 'a', 'b']);
  });

  test('five members means nobody repeats inside four weeks', () {
    final slots = RotationPlanner.plan(
      firstDueDate: first,
      startingUid: 'c',
      orderedUids: ['a', 'b', 'c', 'd', 'e'],
    );
    expect(_who(slots), ['c', 'd', 'e', 'a']);
  });

  test('due dates are exactly a week apart, even across a month end', () {
    final slots = RotationPlanner.plan(
      firstDueDate: first,
      startingUid: 'a',
      orderedUids: ['a', 'b'],
    );
    expect(slots.map((s) => s.dueDate).toList(), [
      DateTime(2026, 10, 26),
      DateTime(2026, 11, 2),
      DateTime(2026, 11, 9),
      DateTime(2026, 11, 16),
    ]);
  });

  test('the number of weeks can be changed', () {
    final slots = RotationPlanner.plan(
      firstDueDate: first,
      startingUid: 'a',
      orderedUids: ['a', 'b'],
      weeks: 6,
    );
    expect(slots.length, 6);
  });

  test('an empty member list is rejected', () {
    expect(
      () => RotationPlanner.plan(
        firstDueDate: first,
        startingUid: 'a',
        orderedUids: [],
      ),
      throwsArgumentError,
    );
  });

  test('a starting member who is not in the list is rejected', () {
    expect(
      () => RotationPlanner.plan(
        firstDueDate: first,
        startingUid: 'z',
        orderedUids: ['a', 'b'],
      ),
      throwsArgumentError,
    );
  });
}
