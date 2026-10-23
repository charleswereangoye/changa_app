import 'package:changa_app/core/error/result.dart';
import 'package:changa_app/features/chores/domain/repositories/chore_repository.dart';

class ReassignChores {
  const ReassignChores(this._repository);

  final ChoreRepository _repository;

  Future<Result<void>> call({
    required String householdId,
    required String fromUid,
    required String toUid,
  }) => _repository.reassignChores(
    householdId: householdId,
    fromUid: fromUid,
    toUid: toUid,
  );
}
