// Owner: C - Person C (Expenses, Dashboard, Documentation)
// Description: Cubit for the Add Expense form: edits, live preview, submit
// ignore_for_file: prefer_initializing_formals

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:changa_app/features/expenses/domain/entities/expense_category.dart';
import 'package:changa_app/features/expenses/domain/entities/new_expense_input.dart';
import 'package:changa_app/features/expenses/domain/entities/split_type.dart';
import 'package:changa_app/features/expenses/domain/usecases/add_expense.dart';

import 'add_expense_state.dart';

class AddExpenseCubit extends Cubit<AddExpenseState> {
  AddExpenseCubit({
    required AddExpense addExpense,
    required String householdId,
    required List<ExpenseParticipant> participants,
    required String currentUid,
    SplitType initialSplitType = SplitType.equal,
  }) : _addExpense = addExpense,
       _householdId = householdId,
       super(
         AddExpenseState(
           participants: participants,
           paidByUid: currentUid,
           selectedUids: [for (final p in participants) p.uid],
           splitType: initialSplitType,
         ),
       );

  final AddExpense _addExpense;
  final String _householdId;

  void amountChanged(String value) =>
      _edit(state.copyWith(amountText: value, amountTouched: true));

  void titleChanged(String value) =>
      _edit(state.copyWith(title: value, titleTouched: true));

  void categoryChanged(ExpenseCategory category) =>
      _edit(state.copyWith(category: category));

  void paidByChanged(String uid) => _edit(state.copyWith(paidByUid: uid));

  /// Switching the split type clears what was typed for the old type.
  void splitTypeChanged(SplitType type) =>
      _edit(state.copyWith(splitType: type, weightTexts: const {}));

  void toggleParticipant(String uid) {
    final selected = List<String>.of(state.selectedUids);
    final weights = Map<String, String>.of(state.weightTexts);

    if (selected.contains(uid)) {
      selected.remove(uid);
      weights.remove(uid);
    } else {
      selected.add(uid);
    }
    _edit(state.copyWith(selectedUids: selected, weightTexts: weights));
  }

  void weightChanged(String uid, String text) {
    final weights = Map<String, String>.of(state.weightTexts);
    if (text.isEmpty) {
      weights.remove(uid);
    } else {
      weights[uid] = text;
    }
    _edit(state.copyWith(weightTexts: weights));
  }

  Future<void> submit() async {
    if (state.status == AddExpenseStatus.submitting || !state.isValid) return;

    emit(
      state.copyWith(
        status: AddExpenseStatus.submitting,
        amountTouched: true,
        titleTouched: true,
      ),
    );

    final input = NewExpenseInput(
      householdId: _householdId,
      title: state.title.trim(),
      category: state.category,
      totalAmount: state.amount!,
      paidByUid: state.paidByUid,
      splitType: state.splitType,
      participantUids: state.selectedUids,
      weights: state.splitType == SplitType.equal ? const {} : state.weights,
    );

    final result = await _addExpense(input);
    final failure = result.failureOrNull;

    if (failure == null) {
      emit(state.copyWith(status: AddExpenseStatus.success));
    } else {
      emit(
        state.copyWith(
          status: AddExpenseStatus.failure,
          failureMessage: failure.message,
        ),
      );
    }
  }

  /// Any edit puts the form back into the editing state.
  void _edit(AddExpenseState next) =>
      emit(next.copyWith(status: AddExpenseStatus.editing));
}
