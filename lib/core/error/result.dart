import 'failures.dart';

/// Sealed Result type representing either a Success or a Failure.
sealed class Result<T> {
  const Result();

  factory Result.success(T data) = Success<T>;
  factory Result.failure(Failure failure) = Error<T>;

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Error<T>;

  T? get dataOrNull => switch (this) {
    Success(data: final d) => d,
    Error() => null,
  };

  Failure? get failureOrNull => switch (this) {
    Success() => null,
    Error(failure: final f) => f,
  };
}

/// Represents successful execution with result data.
class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

/// Represents failed execution with domain Failure.
class Error<T> extends Result<T> {
  final Failure failure;
  const Error(this.failure);
}
