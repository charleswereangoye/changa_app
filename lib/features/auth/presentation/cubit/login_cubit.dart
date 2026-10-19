// Owner: A - Person A (Foundation, Authentication, Profile)
// Description: Cubit managing Login screen state and submission

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit() : super(LoginStateInitial());
}
