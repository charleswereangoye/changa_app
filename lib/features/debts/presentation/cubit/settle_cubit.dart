// Owner: D - Person D (Debts, Settling, Nudges, Notifications, Release Build)
// Description: Cubit managing Settle Up flow

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'settle_state.dart';

class SettleCubit extends Cubit<SettleState> {
  SettleCubit() : super(SettleStateInitial());
}
