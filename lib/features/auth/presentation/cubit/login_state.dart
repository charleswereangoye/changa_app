// Owner: A - Person A (Foundation, Authentication, Profile)
// Description: States for LoginCubit

part of 'login_cubit.dart';

abstract class LoginState extends Equatable {
  const LoginState();

  @override
  List<Object?> get props => [];
}

class LoginStateInitial extends LoginState {}
