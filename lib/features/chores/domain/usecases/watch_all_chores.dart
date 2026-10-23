import 'package:changa_app/features/chores/domain/entities/chore.dart';
import 'package:changa_app/features/chores/domain/repositories/chore_repository.dart';

class WatchAllChores {
  const WatchAllChores(this._repository);

  final ChoreRepository _repository;

  Stream<List<Chore>> call(String householdId) =>
      _repository.watchAllChores(householdId);
}
