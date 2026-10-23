// Owner: C - Person C (Expenses, Dashboard, Documentation)
// Description: ExpenseRepository domain interface

import 'package:changa_app/core/error/result.dart';

import '../entities/expense.dart';
import '../entities/new_expense_input.dart';

abstract class ExpenseRepository {
  /// Saves the expense, its debts, the credits used and an activity line
  /// in one atomic batch.
  Future<Result<Expense>> addExpense(NewExpenseInput input);

  Stream<List<Expense>> watchExpenses(String householdId);

  /// Only the title and the note can be edited.
  Future<Result<void>> updateExpenseNote({
    required String householdId,
    required String expenseId,
    required String title,
    String? note,
  });

  /// Deletes the expense and its debts, and refunds the credits used.
  Future<Result<void>> deleteExpense({
    required String householdId,
    required String expenseId,
  });
}
