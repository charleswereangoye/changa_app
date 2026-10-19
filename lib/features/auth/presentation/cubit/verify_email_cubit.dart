// Owner: A - Person A (Foundation, Authentication, Profile)
// Description: Cubit managing Email Verification screen state and polling

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'verify_email_state.dart';

class VerifyEmailCubit extends Cubit<VerifyEmailState> {
  VerifyEmailCubit() : super(VerifyEmailStateInitial());
}
