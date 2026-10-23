import 'package:changa_app/core/error/result.dart';

import '../entities/household_preview.dart';
import '../repositories/household_repository.dart';

class PreviewHouseholdByPin {
  final HouseholdRepository repository;
  PreviewHouseholdByPin(this.repository);

  Future<Result<HouseholdPreview>> call(String pin) =>
      repository.previewHouseholdByPin(pin);
}
