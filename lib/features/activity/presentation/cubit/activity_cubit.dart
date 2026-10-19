// Owner: B - Person B (Database Design, Security Rules, Household, Activity Feed)
// Description: Cubit managing Activity history screen and filtering

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'activity_state.dart';

class ActivityCubit extends Cubit<ActivityState> {
  ActivityCubit() : super(ActivityStateInitial());
}
