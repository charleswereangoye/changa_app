// Owner: C - Person C (Expenses, Dashboard, Documentation)
// Description: ExpenseModel DTO for Firestore serialization

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:changa_app/core/constants/firestore_paths.dart';
import 'package:changa_app/features/expenses/domain/entities/expense.dart';
import 'package:changa_app/features/expenses/domain/entities/expense_category.dart';
import 'package:changa_app/features/expenses/domain/entities/split_type.dart';

/// Converts an [Expense] to and from a document in
/// `households/{hid}/expenses/{id}`.
class ExpenseModel extends Expense {
  const ExpenseModel({
    required super.id,
    required super.title,
    super.note,
    required super.category,
    required super.totalAmount,
    required super.paidByUid,
    required super.splitType,
    required super.createdAt,
  });

  factory ExpenseModel.fromEntity(Expense expense) {
    return ExpenseModel(
      id: expense.id,
      title: expense.title,
      note: expense.note,
      category: expense.category,
      totalAmount: expense.totalAmount,
      paidByUid: expense.paidByUid,
      splitType: expense.splitType,
      createdAt: expense.createdAt,
    );
  }

  /// Reads an expense document.
  ///
  /// Firestore returns a null timestamp for a write that the server has not
  /// confirmed yet, so a missing `createdAt` falls back to the current time.
  factory ExpenseModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) {
      throw FormatException('Expense ${doc.id} has no data.');
    }

    final createdAt = data[ExpenseFields.createdAt];

    return ExpenseModel(
      id: doc.id,
      title: data[ExpenseFields.title] as String,
      note: data[ExpenseFields.note] as String?,
      category: _enumByName(
        ExpenseCategory.values,
        data[ExpenseFields.category],
        ExpenseFields.category,
      ),
      totalAmount: (data[ExpenseFields.totalAmount] as num).toInt(),
      paidByUid: data[ExpenseFields.paidByUid] as String,
      splitType: _enumByName(
        SplitType.values,
        data[ExpenseFields.splitType],
        ExpenseFields.splitType,
      ),
      createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
    );
  }

  /// Set [useServerTimestamp] to true when creating a new document, so the
  /// server decides the creation time.
  Map<String, dynamic> toMap({bool useServerTimestamp = false}) {
    return {
      ExpenseFields.title: title,
      ExpenseFields.note: note,
      ExpenseFields.category: category.name,
      ExpenseFields.totalAmount: totalAmount,
      ExpenseFields.paidByUid: paidByUid,
      ExpenseFields.splitType: splitType.name,
      ExpenseFields.createdAt: useServerTimestamp
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt),
    };
  }

  static T _enumByName<T extends Enum>(
    List<T> values,
    Object? raw,
    String field,
  ) {
    for (final value in values) {
      if (value.name == raw) return value;
    }
    throw FormatException('Unknown $field value: $raw');
  }
}
