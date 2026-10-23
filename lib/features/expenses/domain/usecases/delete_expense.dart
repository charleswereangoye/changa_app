// Owner: C - Person C (Expenses, Dashboard, Documentation)
// Description: UseCase: Delete expense and refund applied credits

import 'package:changa_app/core/error/result.dart';

import '../repositories/expense_repository.dart';

class DeleteExpense {
  const DeleteExpense(this.repository);

  final ExpenseRepository repository;

  Future<Result<void>> call({
    required String householdId,
    required String expenseId,
  }) =>
      repository.deleteExpense(householdId: householdId, expenseId: expenseId);
}
