// Owner: E - Person E (Chores, Harmony Score, Preferences)
// Description: Cubit managing user app preferences (theme, notifications, defaults)

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'preferences_state.dart';

class PreferencesCubit extends Cubit<PreferencesState> {
  PreferencesCubit() : super(PreferencesStateInitial());
}
