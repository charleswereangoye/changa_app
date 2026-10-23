import 'package:changa_app/core/error/result.dart';
import '../repositories/household_repository.dart';

class LeaveHousehold {
  final HouseholdRepository repository;
  LeaveHousehold(this.repository);

  Future<Result<void>> call(String householdId) => repository.leaveHousehold(householdId);
}