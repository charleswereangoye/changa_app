// Owner: E - Person E (Chores, Harmony Score, Preferences)
// Description: Cubit managing Chore Roster day selection & chore completion

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'chores_state.dart';

class ChoresCubit extends Cubit<ChoresState> {
  ChoresCubit() : super(ChoresStateInitial());
}
