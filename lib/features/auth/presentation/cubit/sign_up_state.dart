part of 'sign_up_cubit.dart';

enum SignUpStatus { initial, loading, success, failure }

class SignUpState extends Equatable {
  final SignUpStatus status;
  final bool isPasswordVisible;
  final String? errorMessage;

  const SignUpState({
    this.status = SignUpStatus.initial,
    this.isPasswordVisible = false,
    this.errorMessage,
  });

  bool get isLoading => status == SignUpStatus.loading;
  bool get isSuccess => status == SignUpStatus.success;
  bool get isFailure => status == SignUpStatus.failure;

  SignUpState copyWith({
    SignUpStatus? status,
    bool? isPasswordVisible,
    String? errorMessage,
  }) {
    return SignUpState(
      status: status ?? this.status,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, isPasswordVisible, errorMessage];
}
