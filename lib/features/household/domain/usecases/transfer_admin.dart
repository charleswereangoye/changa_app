import 'package:changa_app/core/error/result.dart';
import '../repositories/household_repository.dart';

class TransferAdmin {
  final HouseholdRepository repository;
  TransferAdmin(this.repository);

  Future<Result<void>> call({required String householdId, required String newAdminUid}) => 
      repository.transferAdmin(householdId: householdId, newAdminUid: newAdminUid);
}