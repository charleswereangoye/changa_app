import 'package:changa_app/core/error/result.dart';

import '../repositories/household_repository.dart';

class RemoveMember {
  final HouseholdRepository repository;
  RemoveMember(this.repository);

  Future<Result<void>> call({
    required String householdId,
    required String uid,
  }) => repository.removeMember(householdId: householdId, uid: uid);
}
