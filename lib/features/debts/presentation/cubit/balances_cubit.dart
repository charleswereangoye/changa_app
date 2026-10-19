// Owner: D - Person D (Debts, Settling, Nudges, Notifications, Release Build)
// Description: Cubit managing household balances overview

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'balances_state.dart';

class BalancesCubit extends Cubit<BalancesState> {
  BalancesCubit() : super(BalancesStateInitial());
}
