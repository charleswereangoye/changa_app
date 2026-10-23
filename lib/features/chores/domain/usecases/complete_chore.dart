import 'package:changa/core/error/result.dart';
import 'package:changa/features/chores/domain/repositories/chore_repository.dart';

class CompleteChore {
  const CompleteChore(this._repository);

  final ChoreRepository _repository;

  Future<Result<void>> call(String householdId, String choreId) =>
      _repository.completeChore(householdId, choreId);
}
