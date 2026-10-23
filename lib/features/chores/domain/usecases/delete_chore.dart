import 'package:changa/core/error/result.dart';
import 'package:changa/features/chores/domain/repositories/chore_repository.dart';

class DeleteChore {
  const DeleteChore(this._repository);

  final ChoreRepository _repository;

  Future<Result<void>> call(
    String householdId,
    String choreId, {
    bool wholeSeries = false,
  }) => _repository.deleteChore(householdId, choreId, wholeSeries: wholeSeries);
}
