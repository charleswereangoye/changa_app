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
      'bankTransfer' => SettlementMethod.bankTransfer,
      _ => throw ArgumentError.value(
        method,
        'method',
        'Choose cash, momo, or bankTransfer.',
      ),
    };

    final methodLabel = switch (paymentMethod) {
      SettlementMethod.cash => 'Cash',
      SettlementMethod.momo => 'Mobile Money',
      SettlementMethod.bankTransfer => 'Bank Transfer',
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
