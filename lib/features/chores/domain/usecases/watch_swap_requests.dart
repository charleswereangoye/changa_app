import 'package:changa_app/features/chores/domain/entities/swap_request.dart';
import 'package:changa_app/features/chores/domain/repositories/chore_repository.dart';

class WatchSwapRequests {
  const WatchSwapRequests(this._repository);

  final ChoreRepository _repository;

  Stream<List<SwapRequest>> call(String householdId, String uid) =>
      _repository.watchSwapRequests(householdId, uid);
}
