import 'package:changa_app/core/error/result.dart';
import 'package:changa_app/features/chores/domain/repositories/chore_repository.dart';

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
