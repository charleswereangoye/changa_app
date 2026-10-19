// Owner: A - Person A (Foundation, Authentication, Profile)
// Description: Cubit managing Sign-Up screen state and submission

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'sign_up_state.dart';

class SignUpCubit extends Cubit<SignUpState> {
  SignUpCubit() : super(SignUpStateInitial());
}
