// Owner: C - Person C (Expenses, Dashboard, Documentation)
// Description: ExpenseRepository domain interface

import 'package:changa_app/core/error/result.dart';
import 'package:changa_app/features/debts/domain/entities/debt.dart';

import '../entities/expense.dart';
import '../entities/new_expense_input.dart';

abstract class ExpenseRepository {
  /// Saves the expense, its debts, the credits used and an activity line
  /// in one atomic batch.
  Future<Result<Expense>> addExpense(NewExpenseInput input);

  Stream<List<Expense>> watchExpenses(String householdId);

  /// The debts one expense created: one per housemate who owes. Live, so a
  /// payment shows up while the details sheet is open.
  Stream<List<Debt>> watchExpenseDebts({
    required String householdId,
    required String expenseId,
  });

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
