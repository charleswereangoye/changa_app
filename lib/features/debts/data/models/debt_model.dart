// Owner: D - Person D (Debts, Settling, Nudges, Notifications, Release Build)
// Description: DebtModel DTO for Firestore serialization

// TODO(D): Implement DebtModel according to project specification

// Owner: D
// Converts between Firestore documents and the Debt domain entity.

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../domain/entities/debt.dart';
import '../../domain/entities/debt_status.dart';
import '../../../../core/enums/settlement_method.dart';

class DebtModel extends Debt {
  const DebtModel({
    required super.id,
    required super.householdId,
    required super.fromUid,
    required super.toUid,
    required super.amount,
    required super.status,
    required super.createdAt,
    super.settledMethod,
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

    final householdId = document.reference.parent.parent?.id;
    if (householdId == null) {
      throw StateError(
        'Debt document ${document.id} is not inside a household.',
      );
    }

    return DebtModel(
      id: document.id,
      householdId: householdId,
      fromUid: data[DebtFields.debtorUid] as String,
      toUid: data[DebtFields.creditorUid] as String,
      amount: (data[DebtFields.amount] as num).toDouble(),
      status: _enumValue(
        DebtStatus.values,
        data[DebtFields.status],
        DebtFields.status,
      ),
      settledMethod: _nullableEnumValue(
        SettlementMethod.values,
        data[DebtFields.settlementMethod],
        DebtFields.settlementMethod,
      ),
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
      householdId: debt.householdId,
      fromUid: debt.fromUid,
      toUid: debt.toUid,
      amount: debt.amount,
      status: debt.status,
      settledMethod: debt.settledMethod,
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
      DebtFields.debtorUid: fromUid,
      DebtFields.creditorUid: toUid,
      DebtFields.amount: amount,
      DebtFields.status: status.name,
      DebtFields.settlementMethod: settledMethod?.name,
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
      householdId: householdId,
      fromUid: fromUid,
      toUid: toUid,
      amount: amount,
      status: status,
      settledMethod: settledMethod,
      settledAt: settledAt,
      createdAt: createdAt,
    );
  }

  static T _enumValue<T extends Enum>(
    Iterable<T> values,
    Object? rawValue,
    String field,
  ) {
    if (rawValue is String) {
      final value = values.asNameMap()[rawValue];
      if (value != null) return value;
    }
    throw FormatException('Invalid $field value: $rawValue');
  }

  static T? _nullableEnumValue<T extends Enum>(
    Iterable<T> values,
    Object? rawValue,
    String field,
  ) {
    if (rawValue == null) return null;
    return _enumValue(values, rawValue, field);
  }
}
