// Owner: C - Person C (Expenses, Dashboard, Documentation)
// Description: Cubit managing Expense Details modal and deletion

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:changa_app/core/error/failures.dart';
import 'package:changa_app/features/debts/domain/entities/debt.dart';
import 'package:changa_app/features/expenses/domain/entities/expense.dart';
import 'package:changa_app/features/expenses/domain/logic/expense_shares.dart';
import 'package:changa_app/features/expenses/domain/usecases/delete_expense.dart';
import 'package:changa_app/features/expenses/domain/usecases/update_expense_note.dart';
import 'package:changa_app/features/expenses/domain/usecases/watch_expense_debts.dart';

part 'expense_detail_state.dart';

class ExpenseDetailCubit extends Cubit<ExpenseDetailState> {
  ExpenseDetailCubit({
    required this._updateExpenseNote,
    required this._deleteExpense,
    required this._watchExpenseDebts,
    required this._householdId,
    required Expense expense,
    required String currentUid,
  }) : super(
         ExpenseDetailState(
           expense: expense,
           canManage: expense.paidByUid == currentUid,
         ),
       ) {
    _listenToDebts(expense.id);
  }

  final UpdateExpenseNote _updateExpenseNote;
  final DeleteExpense _deleteExpense;
  final WatchExpenseDebts _watchExpenseDebts;
  final String _householdId;

  StreamSubscription<List<Debt>>? _debtsSubscription;

  void _listenToDebts(String expenseId) {
    try {
      _debtsSubscription =
          _watchExpenseDebts(
            householdId: _householdId,
            expenseId: expenseId,
          ).listen(
            (debts) {
              if (isClosed) return;
              emit(
                state.copyWith(
                  debtsStatus: ExpenseDebtsStatus.ready,
                  debts: List<Debt>.unmodifiable(debts),
                ),
              );
            },
            onError: (Object error, StackTrace stackTrace) {
              if (isClosed) return;
              emit(state.copyWith(debtsStatus: ExpenseDebtsStatus.failed));
            },
          );
    } catch (_) {
      emit(state.copyWith(debtsStatus: ExpenseDebtsStatus.failed));
    }
  }

  void startEdit() {
    if (!state.canManage || state.isBusy || state.isEditing) return;
    emit(
      state.copyWith(
        status: ExpenseDetailStatus.editing,
        titleDraft: state.expense.title,
        noteDraft: state.expense.note ?? '',
        clearFailure: true,
      ),
    );
  }

  void cancelEdit() {
    if (state.status != ExpenseDetailStatus.editing) return;
    emit(
      state.copyWith(status: ExpenseDetailStatus.viewing, clearFailure: true),
    );
  }

  void titleChanged(String value) {
    if (state.status != ExpenseDetailStatus.editing) return;
    emit(state.copyWith(titleDraft: value, clearFailure: true));
  }

  void noteChanged(String value) {
    if (state.status != ExpenseDetailStatus.editing) return;
    emit(state.copyWith(noteDraft: value, clearFailure: true));
  }

  Future<void> save() async {
    if (!state.canSave) return;

    final title = state.titleDraft.trim();
    final trimmedNote = state.noteDraft.trim();
    final note = trimmedNote.isEmpty ? null : trimmedNote;

    emit(
      state.copyWith(status: ExpenseDetailStatus.saving, clearFailure: true),
    );

    final result = await _updateExpenseNote(
      householdId: _householdId,
      expenseId: state.expense.id,
      title: title,
      note: note,
    );
    if (isClosed) return;

    final failure = result.failureOrNull;
    if (failure != null) {
      // Keep the draft so the person does not lose what they typed.
      emit(
        state.copyWith(status: ExpenseDetailStatus.editing, failure: failure),
      );
      return;
    }

    final old = state.expense;
    emit(
      state.copyWith(
        status: ExpenseDetailStatus.saved,
        expense: Expense(
          id: old.id,
          title: title,
          note: note,
          category: old.category,
          totalAmount: old.totalAmount,
          paidByUid: old.paidByUid,
          splitType: old.splitType,
          createdAt: old.createdAt,
        ),
        clearFailure: true,
      ),
    );
  }

  Future<void> delete() async {
    // The button is disabled in these cases too. This guard keeps a stray
    // call from reaching the data layer; the data layer still checks again
    // inside its transaction in case a payment lands at the same moment.
    if (!state.canDelete || state.status == ExpenseDetailStatus.deleted) {
      return;
    }

    emit(
      state.copyWith(status: ExpenseDetailStatus.deleting, clearFailure: true),
    );

    final result = await _deleteExpense(
      householdId: _householdId,
      expenseId: state.expense.id,
    );
    if (isClosed) return;

    final failure = result.failureOrNull;
    if (failure != null) {
      emit(
        state.copyWith(status: ExpenseDetailStatus.viewing, failure: failure),
      );
      return;
    }

    emit(
      state.copyWith(status: ExpenseDetailStatus.deleted, clearFailure: true),
    );
  }

  @override
  Future<void> close() async {
    await _debtsSubscription?.cancel();
    _debtsSubscription = null;
    return super.close();
  }
}
