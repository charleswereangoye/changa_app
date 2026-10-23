import 'package:changa_app/core/error/result.dart';

import '../entities/household.dart';
import '../repositories/household_repository.dart';

class JoinHousehold {
  final HouseholdRepository repository;
  JoinHousehold(this.repository);

  Future<Result<Household>> call(String pin) => repository.joinHousehold(pin);
}
