import 'package:changa_app/core/error/result.dart';
import 'package:changa_app/features/chores/domain/entities/new_chore_input.dart';
import 'package:changa_app/features/chores/domain/repositories/chore_repository.dart';

class CreateChore {
  const CreateChore(this._repository);

  final ChoreRepository _repository;

  Future<Result<void>> call(NewChoreInput input) =>
      _repository.createChore(input);
}
