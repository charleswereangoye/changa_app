import 'package:changa/core/error/result.dart';
import 'package:changa/features/chores/domain/repositories/chore_repository.dart';

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
