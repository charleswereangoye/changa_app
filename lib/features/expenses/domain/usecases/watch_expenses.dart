// Owner: C - Person C (Expenses, Dashboard, Documentation)
// Description: UseCase: Stream household expenses

import '../entities/expense.dart';
import '../repositories/expense_repository.dart';

class WatchExpenses {
  const WatchExpenses(this.repository);

  final ExpenseRepository repository;

  Stream<List<Expense>> call(String householdId) =>
      repository.watchExpenses(householdId);
}
