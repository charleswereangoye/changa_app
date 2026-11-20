// Owner: A - Person A (Foundation, Authentication, Profile)
// Description: States for ForgotPasswordCubit

part of 'forgot_password_cubit.dart';

abstract class ForgotPasswordState extends Equatable {
  const ForgotPasswordState();

  @override
  List<Object?> get props => [];
}

class ForgotPasswordStateInitial extends ForgotPasswordState {
  const ForgotPasswordStateInitial();
}

class ForgotPasswordLoading extends ForgotPasswordState {
  const ForgotPasswordLoading();
}

class ForgotPasswordSuccess extends ForgotPasswordState {
  final String message;
  const ForgotPasswordSuccess([
    this.message = 'Check your inbox! We sent password reset instructions.',
  ]);

  @override
  List<Object?> get props => [message];
}

class ForgotPasswordFailure extends ForgotPasswordState {
  final String errorMessage;
  const ForgotPasswordFailure(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}
