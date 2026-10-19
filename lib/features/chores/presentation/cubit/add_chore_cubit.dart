// Owner: E - Person E (Chores, Harmony Score, Preferences)
// Description: Cubit managing Add/Edit Chore form and recurrence settings

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'add_chore_state.dart';

class AddChoreCubit extends Cubit<AddChoreState> {
  AddChoreCubit() : super(AddChoreStateInitial());
}
