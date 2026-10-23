import 'package:changa/core/error/result.dart';
import 'package:changa/features/chores/domain/repositories/chore_repository.dart';

class CancelSwap {
  const CancelSwap(this._repository);

  final ChoreRepository _repository;

  Future<Result<void>> call(String householdId, String requestId) =>
      _repository.cancelSwap(householdId, requestId);
}
