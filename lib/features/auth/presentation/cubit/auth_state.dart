// Owner: A - Person A (Foundation, Authentication, Profile)
// Description: States for global AuthCubit

part of 'auth_cubit.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];

  AppUser? get user => null;
  bool get isAuthenticated => false;
}

class AuthStateInitial extends AuthState {
  const AuthStateInitial();
}

class AuthStateLoading extends AuthState {
  const AuthStateLoading();
}

class Authenticated extends AuthState {
  @override
  final AppUser user;

  const Authenticated(this.user);

  @override
  bool get isAuthenticated => true;

  @override
  List<Object?> get props => [user];
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}

class AuthFailureState extends AuthState {
  final String message;

  const AuthFailureState(this.message);

  @override
  List<Object?> get props => [message];
}
