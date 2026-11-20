// Owner: A - Person A (Foundation, Authentication, Profile)
// Description: Cubit managing Email Verification screen state and polling

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/check_email_verified.dart';
import '../../domain/usecases/send_email_verification.dart';

part 'verify_email_state.dart';

class VerifyEmailCubit extends Cubit<VerifyEmailState> {
  final SendEmailVerification? sendEmailVerification;
  final CheckEmailVerified? checkEmailVerified;
  final AuthRepository? authRepository;

  Timer? _cooldownTimer;

  VerifyEmailCubit({
    this.sendEmailVerification,
    this.checkEmailVerified,
    this.authRepository,
  }) : super(const VerifyEmailState());

  Future<void> resendVerificationEmail() async {
    if (!state.canResend) return;

    emit(state.copyWith(isResending: true, errorMessage: null, message: null));

    if (sendEmailVerification != null) {
      final result = await sendEmailVerification!(const NoParams());
      if (result.isSuccess) {
        _startCooldown(60);
        emit(
          state.copyWith(
            isResending: false,
            message: 'Verification email sent! Check your inbox.',
          ),
        );
      } else {
        emit(
          state.copyWith(
            isResending: false,
            errorMessage:
                result.failureOrNull?.message ??
                'Failed to send verification email.',
          ),
        );
      }
    } else if (authRepository != null) {
      final result = await authRepository!.sendEmailVerification();
      if (result.isSuccess) {
        _startCooldown(60);
        emit(
          state.copyWith(
            isResending: false,
            message: 'Verification email sent! Check your inbox.',
          ),
        );
      } else {
        emit(
          state.copyWith(
            isResending: false,
            errorMessage:
                result.failureOrNull?.message ??
                'Failed to send verification email.',
          ),
        );
      }
    } else {
      _startCooldown(60);
      emit(
        state.copyWith(
          isResending: false,
          message: 'Verification email sent! Check your inbox.',
        ),
      );
    }
  }

  Future<bool> checkVerificationStatus() async {
    emit(state.copyWith(isChecking: true, errorMessage: null));

    bool verified = false;
    if (checkEmailVerified != null) {
      final result = await checkEmailVerified!(const NoParams());
      if (result.isSuccess) {
        verified = result.dataOrNull ?? false;
      }
    } else if (authRepository != null) {
      final result = await authRepository!.reloadAndCheckEmailVerified();
      if (result.isSuccess) {
        verified = result.dataOrNull ?? false;
      }
    } else {
      verified = true;
    }

    if (verified) {
      emit(state.copyWith(isChecking: false, isVerified: true));
      return true;
    } else {
      emit(
        state.copyWith(
          isChecking: false,
          isVerified: false,
          errorMessage: 'Email not verified yet. Please check your inbox and tap the link.',
        ),
      );
      return false;
    }
  }

  void _startCooldown(int seconds) {
    _cooldownTimer?.cancel();
    emit(state.copyWith(resendCooldown: seconds));
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final current = state.resendCooldown;
      if (current <= 1) {
        timer.cancel();
        emit(state.copyWith(resendCooldown: 0));
      } else {
        emit(state.copyWith(resendCooldown: current - 1));
      }
    });
  }

  @override
  Future<void> close() {
    _cooldownTimer?.cancel();
    return super.close();
  }
}
