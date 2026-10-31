// Firestore queries and writes for household debts.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../domain/entities/debt.dart';
import '../../domain/entities/debt_status.dart';
import '../models/debt_model.dart';
import '../../../../core/enums/settlement_method.dart';
import '../../../activity/data/activity_writer.dart';
import '../../../activity/domain/entities/activity.dart';
import '../../../notifications/data/notification_templates.dart';
import '../../../notifications/data/notification_writer.dart';
import '../../domain/logic/settlement_plan.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../../domain/logic/nudge_policy.dart';

class DebtRemoteDataSource {
  const DebtRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _debts(String householdId) {
    return _firestore.collection(FirestorePaths.debts(householdId));
  }

  /// All pending debts in this household.
  Stream<List<Debt>> watchPendingDebts(String householdId) {
    final query = _debts(householdId)
        .where(DebtFields.status, isEqualTo: DebtStatus.pending.name);

    return _watch(query);
  }

  /// Includes pending and settled debts created since the given time.
  /// The Harmony calculator needs both statuses.
  Stream<List<Debt>> watchDebtsSince(String householdId, DateTime since) {
    final query = _debts(householdId).where(
      DebtFields.createdAt,
      isGreaterThanOrEqualTo: Timestamp.fromDate(since),
    );

    return _watch(query);
  }

  /// Watches debts in both directions between two different members.
  Stream<List<Debt>> watchDebtsBetween(
    String householdId,
    String uidA,
    String uidB,
  ) {
    if (uidA == uidB) {
      return Stream<List<Debt>>.value(const <Debt>[]);
    }

    final fromAToB = _watch(
      _debts(householdId)
          .where(DebtFields.debtorUid, isEqualTo: uidA)
          .where(DebtFields.creditorUid, isEqualTo: uidB),
    );

    final fromBToA = _watch(
      _debts(householdId)
          .where(DebtFields.debtorUid, isEqualTo: uidB)
          .where(DebtFields.creditorUid, isEqualTo: uidA),
    );

    return Rx.combineLatest2<List<Debt>, List<Debt>, List<Debt>>(
      fromAToB,
      fromBToA,
      (forward, reverse) {
        final combined = <Debt>[...forward, ...reverse];

        // Newest first, with a stable order for matching timestamps.
        combined.sort((a, b) {
          final dateOrder = b.createdAt.compareTo(a.createdAt);
          return dateOrder != 0 ? dateOrder : a.id.compareTo(b.id);
        });

        return List<Debt>.unmodifiable(combined);
      },
    );
  }

  /// Settles all pending debts between the pair in one batch.
  ///
  /// The batch also writes one activity and one notification.
  Future<void> settleBetween({
    required String householdId,
    required String meUid,
    required String otherUid,
    required String method,
  }) async {
    if (householdId.isEmpty ||
        meUid.isEmpty ||
        otherUid.isEmpty ||
        meUid == otherUid) {
      throw ArgumentError(
        'Settlement requires a household and two different members.',
      );
    }

    // Credits are applied when creating expenses, not manually here.
    final paymentMethod = switch (method) {
      'cash' => SettlementMethod.cash,
      'momo' => SettlementMethod.momo,
      'bank' => SettlementMethod.bank,
      _ => throw ArgumentError.value(
        method,
        'method',
        'Choose cash, momo, or bank.',
      ),
    };

    final methodLabel = switch (paymentMethod) {
      SettlementMethod.cash => 'Cash',
      SettlementMethod.momo => 'Mobile Money',
      SettlementMethod.bank => 'Bank Transfer',
      SettlementMethod.credits => throw StateError(
        'Credits cannot be selected for a manual settlement.',
      ),
    };

    // Read both directions from the server so we do not settle using
    // an offline cache that may be missing pending debts.
    final snapshots = await Future.wait([
      _debts(householdId)
          .where(DebtFields.debtorUid, isEqualTo: meUid)
          .where(DebtFields.creditorUid, isEqualTo: otherUid)
          .get(const GetOptions(source: Source.server)),
      _debts(householdId)
          .where(DebtFields.debtorUid, isEqualTo: otherUid)
          .where(DebtFields.creditorUid, isEqualTo: meUid)
          .get(const GetOptions(source: Source.server)),
    ]);

    final debts = [
      for (final snapshot in snapshots)
        for (final document in snapshot.docs)
          DebtModel.fromFirestore(document).toEntity(),
    ];

    final plan = SettlementPlan.between(
      debts: debts,
      meUid: meUid,
      otherUid: otherUid,
    );

    // Nothing to settle: do not create duplicate history or notifications.
    if (plan.isEmpty) {
      return;
    }

    // Reserve two writes for the activity and notification.
    // Do not split this operation into partially committed batches.
    if (plan.debtIds.length > 498) {
      throw StateError(
        'There are too many debts to settle together in one batch.',
      );
    }

    final actorDocument = await _firestore
        .doc(FirestorePaths.user(meUid))
        .get(const GetOptions(source: Source.server));

    final storedName = actorDocument.data()?[UserFields.fullName] as String?;
    final actorName = storedName == null || storedName.trim().isEmpty
        ? 'A housemate'
        : storedName.trim();

    final batch = _firestore.batch();

    for (final debtId in plan.debtIds) {
      batch.update(_debts(householdId).doc(debtId), {
        DebtFields.status: DebtStatus.settled.name,
        DebtFields.settlementMethod: paymentMethod.name,
        DebtFields.settledAt: FieldValue.serverTimestamp(),
      });
    }

    ActivityWriter(firestore: _firestore).addToBatch(
      batch,
      householdId: householdId,
      type: ActivityType.debtSettled,
      actorUid: meUid,
      targetUid: otherUid,
      amount: plan.amount,
    );

    NotificationWriter(_firestore).addToBatch(
      batch: batch,
      householdId: householdId,
      recipientUid: otherUid,
      actorUid: meUid,
      type: 'settled',
      message: NotificationTemplates.settled(
        name: actorName,
        method: methodLabel,
      ),
      refId: meUid,
    );

    await batch.commit();
  }

  /// Returns a policy failure when the nudge is not allowed.
  /// Returns null after successfully saving the nudge.
  /// Firestore and document-conversion errors propagate to the repository.
  Future<Failure?> sendNudge({
    required String householdId,
    required String fromUid,
    required String toUid,
  }) async {
    if (householdId.isEmpty ||
        fromUid.isEmpty ||
        toUid.isEmpty ||
        fromUid == toUid) {
      return const ValidationFailure(
        'Choose another housemate to send a reminder.',
      );
    }

    // fromUid is the sender here, not necessarily a debt's debtor.
    // Read debts in both directions to establish the sender's net balance.
    final debtSnapshots = await Future.wait([
      _debts(householdId)
          .where(DebtFields.debtorUid, isEqualTo: fromUid)
          .where(DebtFields.creditorUid, isEqualTo: toUid)
          .get(const GetOptions(source: Source.server)),
      _debts(householdId)
          .where(DebtFields.debtorUid, isEqualTo: toUid)
          .where(DebtFields.creditorUid, isEqualTo: fromUid)
          .get(const GetOptions(source: Source.server)),
    ]);

    final balance = SettlementPlan.between(
      debts: [
        for (final snapshot in debtSnapshots)
          for (final document in snapshot.docs)
            DebtModel.fromFirestore(document).toEntity(),
      ],
      meUid: fromUid,
      otherUid: toUid,
    );

    const policy = NudgePolicy(
      cooldown: Duration(hours: AppConstants.nudgeCooldownHours),
    );

    final now = DateTime.now();

    // Check that the recipient owes the sender before reading notifications.
    final balanceFailure = policy.check(balance: balance, now: now);

    if (balanceFailure != null) {
      return balanceFailure;
    }

    final cutoff = now.subtract(policy.cooldown);

    final recentNudges = await _firestore
        .collection(FirestorePaths.notifications(householdId))
        .where(NotificationFields.actorUid, isEqualTo: fromUid)
        .where(NotificationFields.recipientUid, isEqualTo: toUid)
        .where(NotificationFields.type, isEqualTo: 'nudge')
        .where(
          NotificationFields.createdAt,
          isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff),
        )
        .orderBy(NotificationFields.createdAt, descending: true)
        .limit(1)
        .get(const GetOptions(source: Source.server));

    DateTime? lastNudgedAt;

    if (recentNudges.docs.isNotEmpty) {
      lastNudgedAt =
          (recentNudges.docs.first.data()[NotificationFields.createdAt]
                  as Timestamp)
              .toDate();
    }

    final cooldownFailure = policy.check(
      balance: balance,
      now: now,
      lastNudgedAt: lastNudgedAt,
    );

    if (cooldownFailure != null) {
      return cooldownFailure;
    }

    final details = await Future.wait([
      _firestore
          .doc(FirestorePaths.user(toUid))
          .get(const GetOptions(source: Source.server)),
      _firestore
          .doc(FirestorePaths.household(householdId))
          .get(const GetOptions(source: Source.server)),
    ]);

    final storedName = details[0].data()?[UserFields.fullName] as String?;
    final recipientName = storedName == null || storedName.trim().isEmpty
        ? 'there'
        : storedName.trim();

    final storedHousehold = details[1].data()?[HouseholdFields.name] as String?;
    final householdName =
        storedHousehold == null || storedHousehold.trim().isEmpty
        ? 'your household'
        : storedHousehold.trim();

    final batch = _firestore.batch();

    NotificationWriter(_firestore).addToBatch(
      batch: batch,
      householdId: householdId,
      recipientUid: toUid,
      actorUid: fromUid,
      type: 'nudge',
      message: NotificationTemplates.nudge(
        name: recipientName,
        amount: balance.netAmount,
        household: householdName,
      ),
      refId: fromUid,
    );

    // Keep the financial amount out of the shared activity feed.
    ActivityWriter(firestore: _firestore).addToBatch(
      batch,
      householdId: householdId,
      type: ActivityType.nudgeSent,
      actorUid: fromUid,
      targetUid: toUid,
    );

    await batch.commit();

    return null;
  }

  Stream<List<Debt>> _watch(Query<Map<String, dynamic>> query) {
    return query.snapshots().map(
      (snapshot) => List<Debt>.unmodifiable(
        snapshot.docs.map(
          (document) => DebtModel.fromFirestore(document).toEntity(),
        ),
      ),
    );
  }
}
