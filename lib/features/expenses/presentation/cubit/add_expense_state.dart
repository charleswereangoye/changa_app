// Owner: C - Person C (Expenses, Dashboard, Documentation)
// Description: States for AddExpenseCubit

part of 'add_expense_cubit.dart';

abstract class AddExpenseState extends Equatable {
  const AddExpenseState();

  @override
  List<Object?> get props => [];
}

class AddExpenseStateInitial extends AddExpenseState {}
