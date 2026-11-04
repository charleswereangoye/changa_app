part of 'balances_cubit.dart';

sealed class BalancesState extends Equatable {
  const BalancesState();

  @override
  List<Object?> get props => [];
}

class BalancesStateInitial extends BalancesState {
  const BalancesStateInitial();
}

class BalancesStateLoading extends BalancesState {
  const BalancesStateLoading();
}

class BalancesStateLoaded extends BalancesState {
  const BalancesStateLoaded(this.summary);

  final BalanceSummary summary;

  @override
  List<Object?> get props => [summary];
}

class BalancesStateFailure extends BalancesState {
  const BalancesStateFailure(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
