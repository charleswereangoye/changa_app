// Owner: A - Person A (Foundation, Authentication, Profile)
// Description: States for VerifyEmailCubit

part of 'verify_email_cubit.dart';

abstract class VerifyEmailState extends Equatable {
  const VerifyEmailState();

  @override
  List<Object?> get props => [];
}

class VerifyEmailStateInitial extends VerifyEmailState {}
