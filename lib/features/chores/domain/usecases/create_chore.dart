import 'package:changa/core/error/result.dart';
import 'package:changa/features/chores/domain/entities/new_chore_input.dart';
import 'package:changa/features/chores/domain/repositories/chore_repository.dart';

class CreateChore {
  const CreateChore(this._repository);

  final ChoreRepository _repository;

  Future<Result<void>> call(NewChoreInput input) =>
      _repository.createChore(input);
}
