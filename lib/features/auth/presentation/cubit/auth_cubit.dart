// Owner: A - Person A (Foundation, Authentication, Profile)
// Description: Global AuthCubit managing session lifecycle

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository authRepository;
  StreamSubscription<AppUser?>? _authSubscription;

  AuthCubit({required this.authRepository}) : super(const AuthStateInitial()) {
    _init();
  }

  void _init() {
    emit(const AuthStateLoading());
    final current = authRepository.currentUser;
    if (current != null) {
      emit(Authenticated(current));
    }
    _authSubscription = authRepository.authStateChanges.listen(
      (user) {
        if (user != null) {
          emit(Authenticated(user));
        } else {
          emit(const Unauthenticated());
        }
      },
      onError: (error) {
        emit(AuthFailureState(error.toString()));
      },
    );
  }

  Future<void> signOut() async {
    await authRepository.signOut();
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
