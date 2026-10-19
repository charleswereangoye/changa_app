// Owner: C - Person C (Expenses, Dashboard, Documentation)
// Description: States for ExpenseDetailCubit

part of 'expense_detail_cubit.dart';

abstract class ExpenseDetailState extends Equatable {
  const ExpenseDetailState();

  @override
  List<Object?> get props => [];
}

class ExpenseDetailStateInitial extends ExpenseDetailState {}
