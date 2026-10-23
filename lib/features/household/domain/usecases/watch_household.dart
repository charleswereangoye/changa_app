import '../entities/household.dart';
import '../repositories/household_repository.dart';

class WatchHousehold {
  final HouseholdRepository repository;
  WatchHousehold(this.repository);

  Stream<Household?> call(String householdId) => repository.watchHousehold(householdId);
}