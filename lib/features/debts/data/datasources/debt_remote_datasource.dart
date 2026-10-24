// Firestore queries and writes for household debts.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../domain/entities/debt.dart';
import '../../domain/entities/debt_status.dart';
import '../models/debt_model.dart';

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
