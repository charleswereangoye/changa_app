// Owner: D - Person D (Debts, Settling, Nudges, Notifications, Release Build)
// Description: States for BalancesCubit

part of 'balances_cubit.dart';

abstract class BalancesState extends Equatable {
  const BalancesState();

  @override
  List<Object?> get props => [];
}

class BalancesStateInitial extends BalancesState {}
