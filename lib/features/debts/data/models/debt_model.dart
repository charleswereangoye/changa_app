import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/enums/settlement_method.dart';
import '../../domain/entities/debt.dart';
import '../../domain/entities/debt_status.dart';

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
      amount: _readNonNegativeInt(data[DebtFields.amount], DebtFields.amount),
      creditsApplied: _readNonNegativeInt(
        data[DebtFields.creditsApplied],
        DebtFields.creditsApplied,
      ),
      status: _enumValue(
        DebtStatus.values,
        data[DebtFields.status],
        DebtFields.status,
      ),
      settlementMethod: _nullableEnumValue(
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

  /// Use a server timestamp when creating a new document.
  /// Otherwise preserve the existing creation date.
  Map<String, dynamic> toMap({bool useServerTimestamp = false}) {
    return {
      DebtFields.expenseId: expenseId,
      DebtFields.debtorUid: debtorUid,
      DebtFields.creditorUid: creditorUid,
      DebtFields.amount: amount,
      DebtFields.creditsApplied: creditsApplied,
      DebtFields.status: status.name,
      DebtFields.settlementMethod: settlementMethod?.name,
      DebtFields.settledAt: settledAt == null
          ? null
          : Timestamp.fromDate(settledAt!),
      DebtFields.createdAt: useServerTimestamp
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt),
    };
  }

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

  /// Accepts whole-valued numbers without silently truncating fractions.
  /// The domain entity always receives an int.
  static int _readNonNegativeInt(Object? value, String field) {
    if (value is int && value >= 0) {
      return value;
    }

    if (value is double &&
        value.isFinite &&
        value >= 0 &&
        value == value.truncateToDouble()) {
      final converted = value.toInt();

      if (converted.toDouble() == value) {
        return converted;
      }
    }

    throw FormatException(
      '$field must be a finite, non-negative whole number.',
    );
  }

  static T _enumValue<T extends Enum>(
    Iterable<T> values,
    Object? rawValue,
    String field,
  ) {
    if (rawValue is String) {
      final value = values.asNameMap()[rawValue];

      if (value != null) {
        return value;
      }
    }

    throw FormatException('Invalid $field value: $rawValue');
  }

  static T? _nullableEnumValue<T extends Enum>(
    Iterable<T> values,
    Object? rawValue,
    String field,
  ) {
    if (rawValue == null) {
      return null;
    }

    return _enumValue(values, rawValue, field);
  }
}
