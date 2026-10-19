// Owner: A - Person A (Foundation, Authentication, Profile)
// Description: Cubit managing Forgot Password screen state

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'forgot_password_state.dart';

class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  ForgotPasswordCubit() : super(ForgotPasswordStateInitial());
}
