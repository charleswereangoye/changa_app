// Owner: A - Person A (Foundation, Authentication, Profile)
// Description: Global AuthCubit managing session lifecycle

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthStateInitial());
}
