// Owner: A - Person A (Foundation, Authentication, Profile)
// Description: States for ForgotPasswordCubit

part of 'forgot_password_cubit.dart';

abstract class ForgotPasswordState extends Equatable {
  const ForgotPasswordState();

  @override
  List<Object?> get props => [];
}

class ForgotPasswordStateInitial extends ForgotPasswordState {}
