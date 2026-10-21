/// Base failure class with user-friendly error messages.
abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

/// Network connectivity failure.
class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'No internet connection. Please try again.',
  ]);
}

/// Permission / access denied failure.
class PermissionFailure extends Failure {
  const PermissionFailure([
    super.message = 'You do not have permission to perform this action.',
  ]);
}

/// Requested item was not found.
class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Requested resource was not found.']);
}

/// Form or data validation failure.
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Nudge sent within 24h cooldown period.
class NudgeCooldownFailure extends Failure {
  const NudgeCooldownFailure([
    super.message = "You nudged them today. Let's give them a little time.",
  ]);
}

/// Fallback unexpected failure.
class UnknownFailure extends Failure {
  const UnknownFailure([
    super.message = 'An unexpected error occurred. Please try again.',
  ]);
}
