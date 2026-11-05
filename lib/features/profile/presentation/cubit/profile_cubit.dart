// Owner: A - Person A (Foundation, Authentication, Profile)
// Description: Cubit managing Profile screen state

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/entities/app_user.dart';
import '../../domain/usecases/update_profile.dart';
import '../../domain/usecases/watch_user.dart';

part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final WatchUser? watchUser;
  final UpdateProfile? updateProfile;
  StreamSubscription<AppUser?>? _userSubscription;

  ProfileCubit({this.watchUser, this.updateProfile})
    : super(const ProfileStateInitial());

  void loadProfile(String uid) {
    if (uid.isEmpty) return;
    _userSubscription?.cancel();
    final watcher = watchUser;
    if (watcher != null) {
      emit(const ProfileStateLoading());
      _userSubscription = watcher(uid).listen(
        (user) {
          if (user != null) {
            emit(ProfileStateLoaded(user));
          } else {
            emit(const ProfileStateError('User not found'));
          }
        },
        onError: (error) {
          emit(ProfileStateError(error.toString()));
        },
      );
    }
  }

  Future<bool> editProfile({String? fullName, String? phone}) async {
    final updater = updateProfile;
    if (updater == null) return false;
    emit(const ProfileStateLoading());
    final result = await updater(fullName: fullName, phone: phone);
    if (result.isSuccess && result.dataOrNull != null) {
      emit(ProfileStateLoaded(result.dataOrNull!));
      return true;
    } else {
      emit(
        ProfileStateError(
          result.failureOrNull?.message ?? 'Failed to update profile',
        ),
      );
      return false;
    }
  }

  @override
  Future<void> close() {
    _userSubscription?.cancel();
    return super.close();
  }
}
