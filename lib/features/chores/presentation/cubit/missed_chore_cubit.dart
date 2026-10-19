// Owner: E - Person E (Chores, Harmony Score, Preferences)
// Description: Cubit managing missed-chore modal triggers

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'missed_chore_state.dart';

class MissedChoreCubit extends Cubit<MissedChoreState> {
  MissedChoreCubit() : super(MissedChoreStateInitial());
}
