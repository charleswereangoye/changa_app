// Owner: B - Person B (Database Design, Security Rules, Household, Activity Feed)
// Description: Cubit managing Join Household PIN entry & preview

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'join_household_state.dart';

class JoinHouseholdCubit extends Cubit<JoinHouseholdState> {
  JoinHouseholdCubit() : super(JoinHouseholdStateInitial());
}
