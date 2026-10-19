// Owner: B - Person B (Database Design, Security Rules, Household, Activity Feed)
// Description: Cubit managing member administration & PIN changes

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'manage_household_state.dart';

class ManageHouseholdCubit extends Cubit<ManageHouseholdState> {
  ManageHouseholdCubit() : super(ManageHouseholdStateInitial());
}
