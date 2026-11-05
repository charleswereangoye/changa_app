// Owner: A - Person A (Foundation, Authentication, Profile)
// Description: States for ProfileCubit

part of 'profile_cubit.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileStateInitial extends ProfileState {
  const ProfileStateInitial();
}

class ProfileStateLoading extends ProfileState {
  const ProfileStateLoading();
}

class ProfileStateLoaded extends ProfileState {
  final AppUser user;

  const ProfileStateLoaded(this.user);

  @override
  List<Object?> get props => [user];
}

class ProfileStateError extends ProfileState {
  final String message;

  const ProfileStateError(this.message);

  @override
  List<Object?> get props => [message];
}
