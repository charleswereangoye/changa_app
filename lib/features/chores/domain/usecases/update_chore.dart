import 'package:changa/core/error/result.dart';
import 'package:changa/features/chores/domain/entities/chore.dart';
import 'package:changa/features/chores/domain/repositories/chore_repository.dart';

class UpdateChore {
  const UpdateChore(this._repository);

  final ChoreRepository _repository;

  Future<Result<void>> call(String householdId, Chore chore) =>
      _repository.updateChore(householdId, chore);
}
