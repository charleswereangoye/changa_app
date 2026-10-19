// Owner: C - Person C (Expenses, Dashboard, Documentation)
// Description: Cubit managing Add Expense form, live preview, and validation

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'add_expense_state.dart';

class AddExpenseCubit extends Cubit<AddExpenseState> {
  AddExpenseCubit() : super(AddExpenseStateInitial());
}
