// Owner: A - Person A (Foundation, Authentication, Profile)
// Description: Cubit managing Profile screen state

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit() : super(ProfileStateInitial());
}
