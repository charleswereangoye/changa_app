import 'package:changa/core/error/result.dart';
import 'package:changa/features/chores/domain/repositories/chore_repository.dart';

class RequestSwap {
  const RequestSwap(this._repository);

  final ChoreRepository _repository;

  Future<Result<void>> call({
    required String householdId,
    required String choreId,
    required String toUid,
    String? note,
  }) => _repository.requestSwap(
    householdId: householdId,
    choreId: choreId,
    toUid: toUid,
    note: note,
  );
}
