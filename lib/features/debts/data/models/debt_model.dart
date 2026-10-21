// Owner: D - Person D (Debts, Settling, Nudges, Notifications, Release Build)
// Description: DebtModel DTO for Firestore serialization

// TODO(D): Implement DebtModel according to project specification

// Owner: D
// Converts between Firestore documents and the Debt domain entity.

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../domain/entities/debt.dart';

class DebtModel extends Debt {
  const DebtModel({
    required super.id,
    required super.expenseId,
    required super.debtorUid,
    required super.creditorUid,
    required super.amount,
    required super.creditsApplied,
    required super.status,
    required super.createdAt,
    super.settlementMethod,
    super.settledAt,
  });

  /// Reads a debt document.
  ///
  /// Firestore may temporarily return null for a pending server timestamp.
  factory DebtModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    if (data == null) {
      throw StateError('Debt document ${document.id} has no data.');
    }

    return DebtModel(
      id: document.id,
      expenseId: data[DebtFields.expenseId] as String,
      debtorUid: data[DebtFields.debtorUid] as String,
      creditorUid: data[DebtFields.creditorUid] as String,
      amount: data[DebtFields.amount] as int,
      creditsApplied: data[DebtFields.creditsApplied] as int,
      status: data[DebtFields.status] as String,
      settlementMethod: data[DebtFields.settlementMethod] as String?,
      settledAt: (data[DebtFields.settledAt] as Timestamp?)?.toDate(),
      createdAt:
          (data[DebtFields.createdAt] as Timestamp?)?.toDate() ??
          DateTime.now(),
    );
  }

  /// Builds a data-layer model from a domain entity.
  factory DebtModel.fromEntity(Debt debt) {
    return DebtModel(
      id: debt.id,
      expenseId: debt.expenseId,
      debtorUid: debt.debtorUid,
      creditorUid: debt.creditorUid,
      amount: debt.amount,
      creditsApplied: debt.creditsApplied,
      status: debt.status,
      settlementMethod: debt.settlementMethod,
      settledAt: debt.settledAt,
      createdAt: debt.createdAt,
    );
  }

  /// Converts dates to Firestore timestamps.
  ///
  /// Set [useServerTimestamp] to true when creating a new document.
  /// Keep it false when preserving an existing creation date.
  Map<String, dynamic> toMap({bool useServerTimestamp = false}) {
    return {
      DebtFields.expenseId: expenseId,
      DebtFields.debtorUid: debtorUid,
      DebtFields.creditorUid: creditorUid,
      DebtFields.amount: amount,
      DebtFields.creditsApplied: creditsApplied,
      DebtFields.status: status,
      DebtFields.settlementMethod: settlementMethod,
      DebtFields.settledAt: settledAt == null
          ? null
          : Timestamp.fromDate(settledAt!),
      DebtFields.createdAt: useServerTimestamp
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt),
    };
  }

  /// Returns a plain domain entity without Firebase types.
  Debt toEntity() {
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
      createdAt: createdAt,
    );
  }
}
