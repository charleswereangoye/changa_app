part of 'login_cubit.dart';

enum LoginStatus { initial, loading, success, failure }

class LoginState extends Equatable {
  final LoginStatus status;
  final bool isPasswordVisible;
  final String? errorMessage;

  const LoginState({
    this.status = LoginStatus.initial,
    this.isPasswordVisible = false,
    this.errorMessage,
  });

  bool get isLoading => status == LoginStatus.loading;
  bool get isSuccess => status == LoginStatus.success;
  bool get isFailure => status == LoginStatus.failure;

  LoginState copyWith({
    LoginStatus? status,
    bool? isPasswordVisible,
    String? errorMessage,
  }) {
    return LoginState(
      status: status ?? this.status,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, isPasswordVisible, errorMessage];
}
