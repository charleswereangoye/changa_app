import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/auth_repository.dart';

part 'sign_up_state.dart';

class SignUpCubit extends Cubit<SignUpState> {
  final AuthRepository? authRepository;

  SignUpCubit({this.authRepository}) : super(const SignUpState());

  void togglePasswordVisibility() {
    emit(state.copyWith(isPasswordVisible: !state.isPasswordVisible));
  }

  Future<void> signUp({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    if (fullName.trim().isEmpty ||
        email.trim().isEmpty ||
        phone.trim().isEmpty ||
        password.isEmpty) {
      emit(
        state.copyWith(
          status: SignUpStatus.failure,
          errorMessage: 'Please fill in all fields.',
        ),
      );
      return;
    }

    if (password.length < 6) {
      emit(
        state.copyWith(
          status: SignUpStatus.failure,
          errorMessage: 'Password must be at least 6 characters.',
        ),
      );
      return;
    }

    emit(state.copyWith(status: SignUpStatus.loading, errorMessage: null));

    final repo = authRepository;
    if (repo != null) {
      final result = await repo.signUpWithEmail(
        fullName: fullName,
        email: email,
        phone: phone,
        password: password,
      );

      if (result.isSuccess) {
        emit(state.copyWith(status: SignUpStatus.success));
      } else {
        emit(
          state.copyWith(
            status: SignUpStatus.failure,
            errorMessage: result.failureOrNull?.message ?? 'Failed to sign up.',
          ),
        );
      }
    } else {
      emit(state.copyWith(status: SignUpStatus.success));
    }
  }

  Future<void> signUpWithGoogle() async {
    emit(state.copyWith(status: SignUpStatus.loading, errorMessage: null));

    final repo = authRepository;
    if (repo != null) {
      final result = await repo.signInWithGoogle();
      if (result.isSuccess) {
        emit(state.copyWith(status: SignUpStatus.success));
      } else {
        emit(
          state.copyWith(
            status: SignUpStatus.failure,
            errorMessage:
                result.failureOrNull?.message ?? 'Google sign in failed.',
          ),
        );
      }
    } else {
      emit(state.copyWith(status: SignUpStatus.success));
    }
  }

  Future<void> signUpWithApple() async {
    emit(state.copyWith(status: SignUpStatus.loading, errorMessage: null));

    final repo = authRepository;
    if (repo != null) {
      final result = await repo.signInWithApple();
      if (result.isSuccess) {
        emit(state.copyWith(status: SignUpStatus.success));
      } else {
        emit(
          state.copyWith(
            status: SignUpStatus.failure,
            errorMessage:
                result.failureOrNull?.message ?? 'Apple sign in failed.',
          ),
        );
      }
    } else {
      emit(state.copyWith(status: SignUpStatus.success));
    }
  }
}
