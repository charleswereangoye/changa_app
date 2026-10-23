import 'package:changa_app/features/chores/domain/entities/chore.dart';
import 'package:changa_app/features/chores/domain/repositories/chore_repository.dart';

class WatchChoresForDay {
  const WatchChoresForDay(this._repository);

  final ChoreRepository _repository;

  Stream<List<Chore>> call(String householdId, DateTime day) =>
      _repository.watchChoresForDay(householdId, day);
}
