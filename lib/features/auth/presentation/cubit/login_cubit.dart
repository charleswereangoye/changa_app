import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/auth_repository.dart';

part 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final AuthRepository? authRepository;

  LoginCubit({this.authRepository}) : super(const LoginState());

  void togglePasswordVisibility() {
    emit(state.copyWith(isPasswordVisible: !state.isPasswordVisible));
  }

  Future<void> login({required String email, required String password}) async {
    if (email.trim().isEmpty || password.isEmpty) {
      emit(
        state.copyWith(
          status: LoginStatus.failure,
          errorMessage: 'Please enter both email and password.',
        ),
      );
      return;
    }

    emit(state.copyWith(status: LoginStatus.loading, errorMessage: null));

    final repo = authRepository;
    if (repo != null) {
      final result = await repo.loginWithEmail(
        email: email,
        password: password,
      );

      if (result.isSuccess) {
        emit(state.copyWith(status: LoginStatus.success));
      } else {
        emit(
          state.copyWith(
            status: LoginStatus.failure,
            errorMessage: result.failureOrNull?.message ?? 'Failed to log in.',
          ),
        );
      }
    } else {
      emit(state.copyWith(status: LoginStatus.success));
    }
  }

  Future<void> loginWithGoogle() async {
    emit(state.copyWith(status: LoginStatus.loading, errorMessage: null));

    final repo = authRepository;
    if (repo != null) {
      final result = await repo.signInWithGoogle();
      if (result.isSuccess) {
        emit(state.copyWith(status: LoginStatus.success));
      } else {
        emit(
          state.copyWith(
            status: LoginStatus.failure,
            errorMessage:
                result.failureOrNull?.message ?? 'Google sign in failed.',
          ),
        );
      }
    } else {
      emit(state.copyWith(status: LoginStatus.success));
    }
  }

  Future<void> loginWithApple() async {
    emit(state.copyWith(status: LoginStatus.loading, errorMessage: null));

    final repo = authRepository;
    if (repo != null) {
      final result = await repo.signInWithApple();
      if (result.isSuccess) {
        emit(state.copyWith(status: LoginStatus.success));
      } else {
        emit(
          state.copyWith(
            status: LoginStatus.failure,
            errorMessage:
                result.failureOrNull?.message ?? 'Apple sign in failed.',
          ),
        );
      }
    } else {
      emit(state.copyWith(status: LoginStatus.success));
    }
  }
}
