import 'package:changa_app/core/enums/settlement_method.dart';
import 'package:changa_app/features/auth/domain/entities/app_user.dart';
import 'package:changa_app/features/debts/domain/entities/debt.dart';
import 'package:changa_app/features/debts/domain/entities/debt_status.dart';
import 'package:changa_app/features/household/domain/entities/household.dart';
import 'package:changa_app/features/household/domain/entities/member.dart';
import 'package:changa_app/features/notifications/domain/entities/app_notification.dart';

const testHouseholdId = 'household-1';
const testCurrentUid = 'amara';
const testOtherUid = 'jean';

final testCreatedAt = DateTime.utc(2026, 10, 20, 12);

AppUser testUser({
  String uid = testCurrentUid,
  String fullName = 'Amara Okoye',
  String? email,
  String phone = '+250788111222',
  String? householdId = testHouseholdId,
  DateTime? createdAt,
}) {
  return AppUser(
    uid: uid,
    fullName: fullName,
    email: email ?? '$uid@example.com',
    phone: phone,
    householdId: householdId,
    createdAt: createdAt ?? testCreatedAt,
  );
}

Household testHousehold({
  String id = testHouseholdId,
  String name = 'Kigali Nest',
  HouseholdType type = HouseholdType.apartment,
  int expectedMembers = 2,
  String pin = '123456',
  String adminUid = testCurrentUid,
  DateTime? createdAt,
}) {
  return Household(
    id: id,
    name: name,
    type: type,
    expectedMembers: expectedMembers,
    pin: pin,
    adminUid: adminUid,
    createdAt: createdAt ?? testCreatedAt,
  );
}

Member testMember({
  String uid = testCurrentUid,
  MemberRole role = MemberRole.member,
  int credits = 0,
  DateTime? joinedAt,
}) {
  return Member(
    uid: uid,
    role: role,
    credits: credits,
    joinedAt: joinedAt ?? testCreatedAt,
  );
}

/// Amount is whole RWF remaining after credits; creditsApplied is points.
/// Supply settlementMethod and settledAt explicitly for settled fixtures.
Debt testDebt({
  String id = 'debt-1',
  String expenseId = 'expense-1',
  String debtorUid = testOtherUid,
  String creditorUid = testCurrentUid,
  int amount = 6000,
  int creditsApplied = 0,
  DebtStatus status = DebtStatus.pending,
  SettlementMethod? settlementMethod,
  DateTime? settledAt,
  DateTime? createdAt,
}) {
  return Debt(
    id: id,
    expenseId: expenseId,
    debtorUid: debtorUid,
    creditorUid: creditorUid,
    amount: amount,
    creditsApplied: creditsApplied,
    status: status,
    settlementMethod: settlementMethod,
    settledAt: settledAt,
    createdAt: createdAt ?? testCreatedAt,
  );
}

AppNotification testNotification({
  String id = 'notification-1',
  String recipientUid = testCurrentUid,
  String actorUid = testOtherUid,
  String type = 'nudge',
  String title = 'A friendly reminder',
  String body = 'Please check your shared household balance.',
  bool read = false,
  String? refId = 'expense-1',
  DateTime? createdAt,
}) {
  return AppNotification(
    id: id,
    recipientUid: recipientUid,
    actorUid: actorUid,
    type: type,
    title: title,
    body: body,
    read: read,
    refId: refId,
    createdAt: createdAt ?? testCreatedAt,
  );
}
