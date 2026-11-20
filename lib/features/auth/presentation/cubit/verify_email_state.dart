// Owner: A - Person A (Foundation, Authentication, Profile)
// Description: States for VerifyEmailCubit

part of 'verify_email_cubit.dart';

class VerifyEmailState extends Equatable {
  final bool isResending;
  final bool isChecking;
  final bool isVerified;
  final int resendCooldown;
  final String? errorMessage;
  final String? message;

  const VerifyEmailState({
    this.isResending = false,
    this.isChecking = false,
    this.isVerified = false,
    this.resendCooldown = 0,
    this.errorMessage,
    this.message,
  });

  bool get canResend => resendCooldown <= 0 && !isResending;

  VerifyEmailState copyWith({
    bool? isResending,
    bool? isChecking,
    bool? isVerified,
    int? resendCooldown,
    String? errorMessage,
    String? message,
  }) {
    return VerifyEmailState(
      isResending: isResending ?? this.isResending,
      isChecking: isChecking ?? this.isChecking,
      isVerified: isVerified ?? this.isVerified,
      resendCooldown: resendCooldown ?? this.resendCooldown,
      errorMessage: errorMessage,
      message: message,
    );
  }

  @override
  List<Object?> get props => [
    isResending,
    isChecking,
    isVerified,
    resendCooldown,
    errorMessage,
    message,
  ];
}
