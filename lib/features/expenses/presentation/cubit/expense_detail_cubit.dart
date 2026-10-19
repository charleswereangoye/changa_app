// Owner: C - Person C (Expenses, Dashboard, Documentation)
// Description: Cubit managing Expense Details modal and deletion

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'expense_detail_state.dart';

class ExpenseDetailCubit extends Cubit<ExpenseDetailState> {
  ExpenseDetailCubit() : super(ExpenseDetailStateInitial());
}
