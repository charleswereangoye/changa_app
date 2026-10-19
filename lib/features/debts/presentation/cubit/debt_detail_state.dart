// Owner: D - Person D (Debts, Settling, Nudges, Notifications, Release Build)
// Description: States for DebtDetailCubit

part of 'debt_detail_cubit.dart';

abstract class DebtDetailState extends Equatable {
  const DebtDetailState();

  @override
  List<Object?> get props => [];
}

class DebtDetailStateInitial extends DebtDetailState {}
