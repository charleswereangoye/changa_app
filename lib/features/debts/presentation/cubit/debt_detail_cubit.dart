// Owner: D - Person D (Debts, Settling, Nudges, Notifications, Release Build)
// Description: Cubit managing Debt & Nudge itemized breakdown

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'debt_detail_state.dart';

class DebtDetailCubit extends Cubit<DebtDetailState> {
  DebtDetailCubit() : super(DebtDetailStateInitial());
}
