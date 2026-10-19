// Owner: B - Person B (Database Design, Security Rules, Household, Activity Feed)
// Description: Cubit managing Create Household form

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'create_household_state.dart';

class CreateHouseholdCubit extends Cubit<CreateHouseholdState> {
  CreateHouseholdCubit() : super(CreateHouseholdStateInitial());
}
