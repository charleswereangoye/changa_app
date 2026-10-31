enum ChoreRuleKind { validation, permission, notFound }

/// Thrown by the data sources when a rule of the app is broken. The
/// repository turns it into a friendly Failure, so nothing leaks upward.
class ChoreRuleException implements Exception {
  const ChoreRuleException(this.kind, this.message);

  const ChoreRuleException.validation(String message)
    : this(ChoreRuleKind.validation, message);

  const ChoreRuleException.permission(String message)
    : this(ChoreRuleKind.permission, message);

  const ChoreRuleException.notFound(String message)
    : this(ChoreRuleKind.notFound, message);

  final ChoreRuleKind kind;
  final String message;

  @override
  String toString() => 'ChoreRuleException($kind): $message';
}
