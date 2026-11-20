// Owner: A - Person A (Foundation, Authentication, Profile)
// Description: Cubit managing Forgot Password screen state

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/send_password_reset.dart';

part 'forgot_password_state.dart';

class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  final SendPasswordReset? sendPasswordReset;
  final AuthRepository? authRepository;

  ForgotPasswordCubit({this.sendPasswordReset, this.authRepository})
    : super(const ForgotPasswordStateInitial());

  Future<void> submitEmail(String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty) {
      emit(const ForgotPasswordFailure('Please enter your email address.'));
      return;
    }

    emit(const ForgotPasswordLoading());

    if (sendPasswordReset != null) {
      final result = await sendPasswordReset!(trimmed);
      if (result.isSuccess) {
        emit(const ForgotPasswordSuccess());
      } else {
        emit(
          ForgotPasswordFailure(
            result.failureOrNull?.message ?? 'Failed to send reset email.',
          ),
        );
      }
    } else if (authRepository != null) {
      final result = await authRepository!.sendPasswordReset(trimmed);
      if (result.isSuccess) {
        emit(const ForgotPasswordSuccess());
      } else {
        emit(
          ForgotPasswordFailure(
            result.failureOrNull?.message ?? 'Failed to send reset email.',
          ),
        );
      }
    } else {
      emit(const ForgotPasswordSuccess());
    }
  }

  void reset() {
    emit(const ForgotPasswordStateInitial());
  }
}
