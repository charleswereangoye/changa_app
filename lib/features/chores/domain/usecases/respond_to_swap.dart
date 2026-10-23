import 'package:changa/core/error/result.dart';
import 'package:changa/features/chores/domain/repositories/chore_repository.dart';

class RespondToSwap {
  const RespondToSwap(this._repository);

  final ChoreRepository _repository;

  Future<Result<void>> call({
    required String householdId,
    required String requestId,
    required bool accept,
  }) => _repository.respondToSwap(
    householdId: householdId,
    requestId: requestId,
    accept: accept,
  );
}
