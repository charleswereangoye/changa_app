// Owner: A - Person A (Foundation, Authentication, Profile)
// Description: States for SignUpCubit

part of 'sign_up_cubit.dart';

abstract class SignUpState extends Equatable {
  const SignUpState();

  @override
  List<Object?> get props => [];
}

class SignUpStateInitial extends SignUpState {}
