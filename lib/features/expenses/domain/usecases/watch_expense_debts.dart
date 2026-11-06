// Owner: C - Person C (Expenses, Dashboard, Documentation)
// Description: UseCase: Stream the debts created by one expense

import 'package:changa_app/features/debts/domain/entities/debt.dart';

import '../repositories/expense_repository.dart';

class WatchExpenseDebts {
  const WatchExpenseDebts(this.repository);

  final ExpenseRepository repository;

  Stream<List<Debt>> call({
    required String householdId,
    required String expenseId,
  }) => repository.watchExpenseDebts(
    householdId: householdId,
    expenseId: expenseId,
  );
}
