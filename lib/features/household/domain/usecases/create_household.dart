import 'package:changa_app/core/error/result.dart';

import '../entities/household.dart';
import '../repositories/household_repository.dart';

class CreateHousehold {
  final HouseholdRepository repository;
  CreateHousehold(this.repository);

  Future<Result<Household>> call({
    required String name,
    required HouseholdType type,
    required int expectedMembers,
  }) => repository.createHousehold(
    name: name,
    type: type,
    expectedMembers: expectedMembers,
  );
}
