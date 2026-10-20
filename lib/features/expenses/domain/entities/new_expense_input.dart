// Owner: C - Person C (Expenses, Dashboard, Documentation)
// Description: Value object encapsulating new expense form inputs

import 'package:equatable/equatable.dart';

import 'package:changa_app/features/expenses/domain/entities/expense_category.dart';
import 'package:changa_app/features/expenses/domain/entities/split_type.dart';

/// Everything the Add Expense form collects, before anything is saved.
class NewExpenseInput extends Equatable {
  const NewExpenseInput({
    required this.householdId,
    required this.title,
    this.note,
    required this.category,
    required this.totalAmount,
    required this.paidByUid,
    required this.splitType,
    required this.participantUids,
    this.weights = const {},
  });

  final String householdId;
  final String title;
  final String? note;
  final ExpenseCategory category;

  /// Whole RWF, no decimals.
  final int totalAmount;
  final String paidByUid;
  final SplitType splitType;

  /// Housemates who share the cost (the payer may be one of them), in the
  /// order they were selected. The order decides who pays the extra RWF
  /// when an equal split has a remainder.
  final List<String> participantUids;

  /// Only for percent and exact splits: uid -> percent or RWF amount.
  /// Empty for an equal split.
  final Map<String, int> weights;

  @override
  List<Object?> get props => [
    householdId,
    title,
    note,
    category,
    totalAmount,
    paidByUid,
    splitType,
    participantUids,
    weights,
  ];
}
