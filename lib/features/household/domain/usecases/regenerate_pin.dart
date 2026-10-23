import 'package:changa_app/core/error/result.dart';

import '../repositories/household_repository.dart';

class RegeneratePin {
  final HouseholdRepository repository;
  RegeneratePin(this.repository);

  Future<Result<String>> call(String householdId) =>
      repository.regeneratePin(householdId);
}
