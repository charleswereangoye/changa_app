import 'package:changa_app/core/error/result.dart';
import 'package:changa_app/features/chores/domain/repositories/chore_repository.dart';

class CancelSwap {
  const CancelSwap(this._repository);

  final ChoreRepository _repository;

  Future<Result<void>> call(String householdId, String requestId) =>
      _repository.cancelSwap(householdId, requestId);
}
