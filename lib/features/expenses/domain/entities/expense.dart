// Owner: C - Person C (Expenses, Dashboard, Documentation)
// Description: Expense domain entity

import 'package:equatable/equatable.dart';

import 'package:changa_app/features/expenses/domain/entities/expense_category.dart';
import 'package:changa_app/features/expenses/domain/entities/split_type.dart';

/// One shared cost that a housemate paid for, e.g. "Groceries, 24,000 RWF".
///
/// Plain Dart only: no Firebase in the domain layer. The data layer
/// converts to and from Firestore.
class Expense extends Equatable {
  const Expense({
    required this.id,
    required this.title,
    this.note,
    required this.category,
    required this.totalAmount,
    required this.paidByUid,
    required this.splitType,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String? note;
  final ExpenseCategory category;

  /// Whole RWF, no decimals.
  final int totalAmount;
  final String paidByUid;
  final SplitType splitType;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
    id,
    title,
    note,
    category,
    totalAmount,
    paidByUid,
    splitType,
    createdAt,
  ];
}
