import 'package:changa_app/core/error/result.dart';

import '../entities/household.dart';
import '../entities/household_preview.dart';
import '../entities/member.dart';

abstract class HouseholdRepository {
  Stream<Household?> watchHousehold(String householdId);

  Stream<List<Member>> watchMembers(String householdId);

  Future<Result<Household>> createHousehold({
    required String name,
    required HouseholdType type,
    required int expectedMembers,
  });

  Future<Result<HouseholdPreview>> previewHouseholdByPin(String pin);

  Future<Result<Household>> joinHousehold(String pin);

  Future<Result<String>> regeneratePin(String householdId);

  Future<Result<void>> removeMember({
    required String householdId,
    required String uid,
  });

  Future<Result<void>> transferAdmin({
    required String householdId,
    required String newAdminUid,
  });

  Future<Result<void>> leaveHousehold(String householdId);
}
