import 'package:changa_app/core/constants/firestore_paths.dart';
import 'package:flutter_test/flutter_test.dart';

int _segments(String path) => path.split('/').length;

void main() {
  const hid = 'h1';

  group('FirestorePaths', () {
    test('top-level paths', () {
      expect(FirestorePaths.users, 'users');
      expect(FirestorePaths.user('u1'), 'users/u1');
      expect(FirestorePaths.householdPins, 'householdPins');
      expect(FirestorePaths.householdPin('482916'), 'householdPins/482916');
      expect(FirestorePaths.households, 'households');
      expect(FirestorePaths.household(hid), 'households/h1');
    });

    test('sub-collections always live inside a household', () {
      expect(FirestorePaths.members(hid), 'households/h1/members');
      expect(FirestorePaths.member(hid, 'u1'), 'households/h1/members/u1');
      expect(FirestorePaths.expense(hid, 'e1'), 'households/h1/expenses/e1');
      expect(FirestorePaths.debt(hid, 'd1'), 'households/h1/debts/d1');
      expect(FirestorePaths.chore(hid, 'c1'), 'households/h1/chores/c1');
      expect(
        FirestorePaths.swapRequest(hid, 's1'),
        'households/h1/swapRequests/s1',
      );
      expect(FirestorePaths.activity(hid, 'a1'), 'households/h1/activities/a1');
      expect(
        FirestorePaths.notification(hid, 'n1'),
        'households/h1/notifications/n1',
      );
    });

    test('collection paths have an odd number of segments', () {
      final collections = [
        FirestorePaths.users,
        FirestorePaths.householdPins,
        FirestorePaths.households,
        FirestorePaths.members(hid),
        FirestorePaths.expenses(hid),
        FirestorePaths.debts(hid),
        FirestorePaths.chores(hid),
        FirestorePaths.swapRequests(hid),
        FirestorePaths.activities(hid),
        FirestorePaths.notifications(hid),
      ];
      for (final path in collections) {
        expect(
          _segments(path).isOdd,
          isTrue,
          reason: '$path is not a collection',
        );
      }
    });

    test('document paths have an even number of segments', () {
      final documents = [
        FirestorePaths.user('x'),
        FirestorePaths.householdPin('x'),
        FirestorePaths.household('x'),
        FirestorePaths.member(hid, 'x'),
        FirestorePaths.expense(hid, 'x'),
        FirestorePaths.debt(hid, 'x'),
        FirestorePaths.chore(hid, 'x'),
        FirestorePaths.swapRequest(hid, 'x'),
        FirestorePaths.activity(hid, 'x'),
        FirestorePaths.notification(hid, 'x'),
      ];
      for (final path in documents) {
        expect(
          _segments(path).isEven,
          isTrue,
          reason: '$path is not a document',
        );
      }
    });

    test('an empty id is rejected while developing', () {
      expect(() => FirestorePaths.user(''), throwsAssertionError);
      expect(() => FirestorePaths.member(hid, ''), throwsAssertionError);
      expect(() => FirestorePaths.members(''), throwsAssertionError);
    });
  });

  group('field names', () {
    test('match the ERD spelling for the fields other features query on', () {
      expect(UserFields.householdId, 'householdId');
      expect(HouseholdFields.adminUid, 'adminUid');
      expect(MemberFields.credits, 'credits');
      expect(DebtFields.debtorUid, 'debtorUid');
      expect(DebtFields.creditorUid, 'creditorUid');
      expect(DebtFields.status, 'status');
      expect(ChoreFields.dueDate, 'dueDate');
      expect(ChoreFields.assignedToUid, 'assignedToUid');
      expect(NotificationFields.recipientUid, 'recipientUid');
      expect(ActivityFields.createdAt, 'createdAt');
    });
  });
}
