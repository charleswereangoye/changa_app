import 'package:changa_app/core/error/result.dart';
import 'package:changa_app/features/chores/domain/repositories/chore_repository.dart';

class DeleteChore {
  const DeleteChore(this._repository);

  final ChoreRepository _repository;

  Future<Result<void>> call(
    String householdId,
    String choreId, {
    bool wholeSeries = false,
  }) => _repository.deleteChore(householdId, choreId, wholeSeries: wholeSeries);
}
