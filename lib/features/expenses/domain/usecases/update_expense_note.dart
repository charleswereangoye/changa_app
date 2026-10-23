// Owner: C - Person C (Expenses, Dashboard, Documentation)
// Description: UseCase: Update title and note of an existing expense

import 'package:changa_app/core/error/result.dart';

import '../repositories/expense_repository.dart';

class UpdateExpenseNote {
  const UpdateExpenseNote(this.repository);

  final ExpenseRepository repository;

  Future<Result<void>> call({
    required String householdId,
    required String expenseId,
    required String title,
    String? note,
  }) => repository.updateExpenseNote(
    householdId: householdId,
    expenseId: expenseId,
    title: title,
    note: note,
  );
}
