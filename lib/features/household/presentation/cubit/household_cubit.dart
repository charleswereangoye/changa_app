// Owner: B - Person B (Database Design, Security Rules, Household, Activity Feed)
// Description: Global HouseholdCubit managing current household and members

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'household_state.dart';

class HouseholdCubit extends Cubit<HouseholdState> {
  HouseholdCubit() : super(HouseholdStateInitial());
}
