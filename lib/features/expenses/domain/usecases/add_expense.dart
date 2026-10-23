// Owner: C - Person C (Expenses, Dashboard, Documentation)
// Description: UseCase: Add expense in atomic batch write

import 'package:changa_app/core/error/result.dart';

import '../entities/expense.dart';
import '../entities/new_expense_input.dart';
import '../repositories/expense_repository.dart';

class AddExpense {
  const AddExpense(this.repository);

  final ExpenseRepository repository;

  Future<Result<Expense>> call(NewExpenseInput input) =>
      repository.addExpense(input);
}
