// Owner: D - Person D (Debts, Settling, Nudges, Notifications, Release Build)
// Description: States for SettleCubit

part of 'settle_cubit.dart';

abstract class SettleState extends Equatable {
  const SettleState();

  @override
  List<Object?> get props => [];
}

class SettleStateInitial extends SettleState {}
