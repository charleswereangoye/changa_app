// Owner: E - Person E (Chores, Harmony Score, Preferences)
// Description: Cubit managing chore swap requests

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'swap_state.dart';

class SwapCubit extends Cubit<SwapState> {
  SwapCubit() : super(SwapStateInitial());
}
