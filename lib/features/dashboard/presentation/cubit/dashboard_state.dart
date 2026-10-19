// Owner: C - Person C (Expenses, Dashboard, Documentation)
// Description: States for DashboardCubit

part of 'dashboard_cubit.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardStateInitial extends DashboardState {}
