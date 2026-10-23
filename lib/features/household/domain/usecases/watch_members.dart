import '../entities/member.dart';
import '../repositories/household_repository.dart';

class WatchMembers {
  final HouseholdRepository repository;
  WatchMembers(this.repository);

  Stream<List<Member>> call(String householdId) =>
      repository.watchMembers(householdId);
}
