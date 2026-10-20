/// Names of the 10 collections
abstract final class FirestoreCollections {
  // Top level
  static const String users = 'users';
  static const String householdPins = 'householdPins';
  static const String households = 'households';

  // Sub-collections of households/{hid}
  static const String members = 'members';
  static const String expenses = 'expenses';
  static const String debts = 'debts';
  static const String chores = 'chores';
  static const String swapRequests = 'swapRequests';
  static const String activities = 'activities';
  static const String notifications = 'notifications';
}

/// Full paths
/// A collection path has an ODD number of segments, a document path an EVEN number
/// Firestore throws if you mix them up, and the test for this file checks it
abstract final class FirestorePaths {
  //  top level
  static const String users = FirestoreCollections.users;
  static String user(String uid) => '$users/${_id(uid, 'uid')}';

  static const String householdPins = FirestoreCollections.householdPins;
  static String householdPin(String pin) => '$householdPins/${_id(pin, 'pin')}';

  static const String households = FirestoreCollections.households;
  static String household(String householdId) =>
      '$households/${_id(householdId, 'householdId')}';

  // sub-collections of one household
  static String members(String householdId) =>
      '${household(householdId)}/${FirestoreCollections.members}';
  static String member(String householdId, String uid) =>
      '${members(householdId)}/${_id(uid, 'uid')}';

  static String expenses(String householdId) =>
      '${household(householdId)}/${FirestoreCollections.expenses}';
  static String expense(String householdId, String expenseId) =>
      '${expenses(householdId)}/${_id(expenseId, 'expenseId')}';

  static String debts(String householdId) =>
      '${household(householdId)}/${FirestoreCollections.debts}';
  static String debt(String householdId, String debtId) =>
      '${debts(householdId)}/${_id(debtId, 'debtId')}';

  static String chores(String householdId) =>
      '${household(householdId)}/${FirestoreCollections.chores}';
  static String chore(String householdId, String choreId) =>
      '${chores(householdId)}/${_id(choreId, 'choreId')}';

  static String swapRequests(String householdId) =>
      '${household(householdId)}/${FirestoreCollections.swapRequests}';
  static String swapRequest(String householdId, String requestId) =>
      '${swapRequests(householdId)}/${_id(requestId, 'requestId')}';

  static String activities(String householdId) =>
      '${household(householdId)}/${FirestoreCollections.activities}';
  static String activity(String householdId, String activityId) =>
      '${activities(householdId)}/${_id(activityId, 'activityId')}';

  static String notifications(String householdId) =>
      '${household(householdId)}/${FirestoreCollections.notifications}';
  static String notification(String householdId, String notificationId) =>
      '${notifications(householdId)}/${_id(notificationId, 'notificationId')}';

  /// An empty id would silently produce a wrong path such as `users/`
  static String _id(String value, String name) {
    assert(value.isNotEmpty, '$name must not be empty');
    return value;
  }
}

// Stored fields, one class per collection. Each name is equal to its value on purpose

/// users/{uid}
abstract final class UserFields {
  static const String fullName = 'fullName';
  static const String email = 'email';
  static const String phone = 'phone';
  static const String householdId = 'householdId'; // nullable
  static const String createdAt = 'createdAt';
}

/// householdPins/{pin}
abstract final class PinFields {
  static const String householdId = 'householdId';
  static const String createdAt = 'createdAt';
}

/// households/{hid}
abstract final class HouseholdFields {
  static const String name = 'name';
  static const String type = 'type'; // apartment | dorm | house
  static const String expectedMembers = 'expectedMembers';
  static const String pin = 'pin';
  static const String adminUid = 'adminUid';
  static const String createdAt = 'createdAt';
}

/// households/{hid}/members/{uid}
abstract final class MemberFields {
  static const String role = 'role'; // admin | member
  static const String credits = 'credits'; // never below 0
  static const String joinedAt = 'joinedAt';
}

/// households/{hid}/expenses/{id}
abstract final class ExpenseFields {
  static const String title = 'title';
  static const String note = 'note'; // nullable
  static const String category = 'category';
  static const String totalAmount = 'totalAmount';
  static const String paidByUid = 'paidByUid';
  static const String splitType = 'splitType'; // equal, percent, exact
  static const String createdAt = 'createdAt';
}

/// households/{hid}/debts/{id}
abstract final class DebtFields {
  static const String expenseId = 'expenseId';
  static const String debtorUid = 'debtorUid';
  static const String creditorUid = 'creditorUid';
  static const String amount = 'amount';
  static const String creditsApplied = 'creditsApplied';
  static const String status = 'status'; // pending or settled
  static const String settlementMethod = 'settlementMethod'; // nullable
  static const String settledAt = 'settledAt'; // nullable
  static const String createdAt = 'createdAt';
}

/// households/{hid}/chores/{id}
abstract final class ChoreFields {
  static const String seriesId =
      'seriesId'; // nullable, set on recurring chores
  static const String title = 'title';
  static const String description = 'description'; // nullable
  static const String difficulty = 'difficulty'; // easy or medium or hard
  static const String assignedToUid = 'assignedToUid';
  static const String dueDate = 'dueDate';
  static const String status = 'status'; // pending or done
  static const String completedAt = 'completedAt'; // nullable
  static const String creditsAwarded = 'creditsAwarded'; // nullable
  static const String createdByUid = 'createdByUid';
  static const String createdAt = 'createdAt';
}

/// households/{hid}/swapRequests/{id}
abstract final class SwapRequestFields {
  static const String choreId = 'choreId';
  static const String fromUid = 'fromUid';
  static const String toUid = 'toUid';
  static const String note = 'note'; // nullable
  static const String status =
      'status'; // pending or accepted or declined or cancelled
  static const String createdAt = 'createdAt';
}

/// households/{hid}/activities/{id}
abstract final class ActivityFields {
  static const String type = 'type';
  static const String actorUid = 'actorUid';
  static const String targetUid = 'targetUid'; // nullable
  static const String refId = 'refId'; // nullable, not an enforced foreign key
  static const String amount = 'amount'; // nullable
  static const String createdAt = 'createdAt';
}

/// households/{hid}/notifications/{id}
abstract final class NotificationFields {
  static const String recipientUid = 'recipientUid';
  static const String actorUid = 'actorUid';
  static const String type = 'type';
  static const String title = 'title';
  static const String body = 'body';
  static const String refId = 'refId'; // nullable
  static const String read = 'read';
  static const String createdAt = 'createdAt';
}
