// Owner: A - Person A (Foundation, Authentication, Profile)
// Description: States for ProfileCubit

part of 'profile_cubit.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileStateInitial extends ProfileState {}
