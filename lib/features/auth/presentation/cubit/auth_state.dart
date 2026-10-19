// Owner: A - Person A (Foundation, Authentication, Profile)
// Description: States for global AuthCubit

part of 'auth_cubit.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthStateInitial extends AuthState {}
