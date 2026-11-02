// Owner: C - Person C (Expenses, Dashboard, Documentation)
// Description: Tests for ExpenseDetailCubit (edit note, delete, guards)

import 'dart:async';

import 'package:changa_app/core/error/failures.dart';
import 'package:changa_app/core/error/result.dart';
import 'package:changa_app/features/expenses/domain/entities/expense.dart';
import 'package:changa_app/features/expenses/domain/entities/expense_category.dart';
import 'package:changa_app/features/expenses/domain/entities/new_expense_input.dart';
import 'package:changa_app/features/expenses/domain/entities/split_type.dart';
import 'package:changa_app/features/expenses/domain/repositories/expense_repository.dart';
import 'package:changa_app/features/expenses/domain/usecases/delete_expense.dart';
import 'package:changa_app/features/expenses/domain/usecases/update_expense_note.dart';
import 'package:changa_app/features/expenses/presentation/cubit/expense_detail_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeDetailRepository implements ExpenseRepository {
  int updateCalls = 0;
  int deleteCalls = 0;
  String? lastTitle;
  String? lastNote;

  /// When set, update and delete wait until the test completes it.
  Completer<Result<void>>? gate;
  Result<void> nextResult = Result<void>.success(null);

  @override
  Future<Result<void>> updateExpenseNote({
    required String householdId,
    required String expenseId,
    required String title,
    String? note,
  }) {
    updateCalls++;
    lastTitle = title;
    lastNote = note;
    return gate?.future ?? Future.value(nextResult);
  }

  @override
  Future<Result<void>> deleteExpense({
    required String householdId,
    required String expenseId,
  }) {
    deleteCalls++;
    return gate?.future ?? Future.value(nextResult);
  }

  @override
  Future<Result<Expense>> addExpense(NewExpenseInput input) =>
      throw UnimplementedError();

  @override
  Stream<List<Expense>> watchExpenses(String householdId) =>
      throw UnimplementedError();
}

Expense sample({String paidBy = 'amara', String? note}) => Expense(
  id: 'e1',
  title: 'Groceries',
  note: note,
  category: ExpenseCategory.groceries,
  totalAmount: 12000,
  paidByUid: paidBy,
  splitType: SplitType.equal,
  createdAt: DateTime(2026, 10, 30),
);

ExpenseDetailCubit build(
  FakeDetailRepository repo, {
  String currentUid = 'amara',
  Expense? expense,
}) {
  return ExpenseDetailCubit(
    updateExpenseNote: UpdateExpenseNote(repo),
    deleteExpense: DeleteExpense(repo),
    householdId: 'h1',
    expense: expense ?? sample(),
    currentUid: currentUid,
  );
}

void main() {
  late FakeDetailRepository repo;

  setUp(() => repo = FakeDetailRepository());

  test('the payer can manage the expense, others cannot', () {
    expect(build(repo).state.canManage, isTrue);
    expect(build(repo, currentUid: 'chloe').state.canManage, isFalse);
  });

  test('startEdit copies the saved title and note into the draft', () {
    final cubit = build(repo, expense: sample(note: 'Market run'));
    cubit.startEdit();

    expect(cubit.state.status, ExpenseDetailStatus.editing);
    expect(cubit.state.titleDraft, 'Groceries');
    expect(cubit.state.noteDraft, 'Market run');
  });

  test('someone who did not pay cannot edit or delete', () async {
    final cubit = build(repo, currentUid: 'chloe');
    cubit.startEdit();
    await cubit.delete();

    expect(cubit.state.status, ExpenseDetailStatus.viewing);
    expect(repo.updateCalls, 0);
    expect(repo.deleteCalls, 0);
  });

  test('cancelEdit goes back to viewing', () {
    final cubit = build(repo)..startEdit();
    cubit.titleChanged('Something else');
    cubit.cancelEdit();

    expect(cubit.state.status, ExpenseDetailStatus.viewing);
    expect(cubit.state.expense.title, 'Groceries');
  });

  test('save sends trimmed title, a blank note as null, and updates', () async {
    final cubit = build(repo)..startEdit();
    cubit.titleChanged('  Weekly groceries  ');
    cubit.noteChanged('   ');
    await cubit.save();

    expect(repo.lastTitle, 'Weekly groceries');
    expect(repo.lastNote, isNull);
    expect(cubit.state.status, ExpenseDetailStatus.saved);
    expect(cubit.state.expense.title, 'Weekly groceries');
    expect(cubit.state.expense.note, isNull);
    expect(cubit.state.expense.totalAmount, 12000);
  });

  test('a title that is too short cannot be saved', () async {
    final cubit = build(repo)..startEdit();
    cubit.titleChanged('ab');

    expect(cubit.state.titleProblem, isNotNull);
    expect(cubit.state.canSave, isFalse);
    await cubit.save();
    expect(repo.updateCalls, 0);
  });

  test('saving without any change does nothing', () async {
    final cubit = build(repo)..startEdit();
    await cubit.save();

    expect(repo.updateCalls, 0);
    expect(cubit.state.status, ExpenseDetailStatus.editing);
  });

  test('a failed save keeps the draft and shows the failure', () async {
    repo.nextResult = Result<void>.failure(const NetworkFailure());
    final cubit = build(repo)..startEdit();
    cubit.titleChanged('Weekly groceries');
    await cubit.save();

    expect(cubit.state.status, ExpenseDetailStatus.editing);
    expect(cubit.state.titleDraft, 'Weekly groceries');
    expect(cubit.state.failure, isA<NetworkFailure>());
    expect(cubit.state.expense.title, 'Groceries');
  });

  test('edits are ignored while a save is in flight', () async {
    repo.gate = Completer<Result<void>>();
    final cubit = build(repo)..startEdit();
    cubit.titleChanged('Weekly groceries');
    final saving = cubit.save();

    cubit.titleChanged('Changed mid-save');
    cubit.cancelEdit();
    expect(cubit.state.status, ExpenseDetailStatus.saving);
    expect(cubit.state.titleDraft, 'Weekly groceries');

    repo.gate!.complete(Result<void>.success(null));
    await saving;
    expect(repo.updateCalls, 1);
  });

  test('delete succeeds and ends in deleted', () async {
    final cubit = build(repo);
    await cubit.delete();

    expect(repo.deleteCalls, 1);
    expect(cubit.state.status, ExpenseDetailStatus.deleted);
  });

  test('a failed delete goes back to viewing with the failure', () async {
    repo.nextResult = Result<void>.failure(
      const ValidationFailure('Someone already paid their share.'),
    );
    final cubit = build(repo);
    await cubit.delete();

    expect(cubit.state.status, ExpenseDetailStatus.viewing);
    expect(cubit.state.failure, isA<ValidationFailure>());
  });

  test('tapping delete twice only deletes once', () async {
    repo.gate = Completer<Result<void>>();
    final cubit = build(repo);
    final first = cubit.delete();
    final second = cubit.delete();

    repo.gate!.complete(Result<void>.success(null));
    await Future.wait([first, second]);
    expect(repo.deleteCalls, 1);
  });

  test('closing the cubit during a save does not throw', () async {
    repo.gate = Completer<Result<void>>();
    final cubit = build(repo)..startEdit();
    cubit.titleChanged('Weekly groceries');
    final saving = cubit.save();

    await cubit.close();
    repo.gate!.complete(Result<void>.success(null));
    await saving;
  });
}
