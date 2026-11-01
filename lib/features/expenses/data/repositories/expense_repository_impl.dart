// Owner: C - Person C (Expenses, Dashboard, Documentation)
// Description: ExpenseRepository implementation backed by Firestore

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:changa_app/core/error/failures.dart';
import 'package:changa_app/core/error/result.dart';
import 'package:changa_app/features/expenses/data/datasources/expense_remote_datasource.dart';
import 'package:changa_app/features/expenses/domain/entities/expense.dart';
import 'package:changa_app/features/expenses/domain/entities/new_expense_input.dart';
import 'package:changa_app/features/expenses/domain/logic/split_calculator.dart';
import 'package:changa_app/features/expenses/domain/repositories/expense_repository.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  const ExpenseRepositoryImpl({
    required ExpenseRemoteDataSource remoteDataSource,
  }) : _remote = remoteDataSource;

  final ExpenseRemoteDataSource _remote;

  @override
  Future<Result<Expense>> addExpense(NewExpenseInput input) async {
    final first = await _guard(() => _remote.addExpense(input));

    // The security rules refuse a batch that would make a credit balance
    // negative. That happens when someone's credits changed between our read
    // and our write, so read again and try once more.
    if (first.failureOrNull is PermissionFailure) {
      return _guard(() => _remote.addExpense(input));
    }
    return first;
  }

  @override
  Stream<List<Expense>> watchExpenses(String householdId) {
    return _remote.watchExpenses(householdId);
  }

  @override
  Future<Result<void>> updateExpenseNote({
    required String householdId,
    required String expenseId,
    required String title,
    String? note,
  }) {
    return _guard(
      () => _remote.updateExpenseNote(
        householdId: householdId,
        expenseId: expenseId,
        title: title,
        note: note,
      ),
    );
  }

  @override
  Future<Result<void>> deleteExpense({
    required String householdId,
    required String expenseId,
  }) {
    return _guard(
      () =>
          _remote.deleteExpense(householdId: householdId, expenseId: expenseId),
    );
  }

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Result.success(await action());
    } on ExpenseException catch (e) {
      return Result.failure(e.failure);
    } on SplitInputException catch (e) {
      return Result.failure(ValidationFailure(e.message));
    } on FirebaseException catch (e) {
      return Result.failure(_mapFirebase(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  Failure _mapFirebase(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return const PermissionFailure();
      case 'unavailable':
      case 'deadline-exceeded':
        return const NetworkFailure();
      case 'not-found':
        return const NotFoundFailure();
      default:
        return UnknownFailure(e.message ?? e.toString());
    }
  }
}
