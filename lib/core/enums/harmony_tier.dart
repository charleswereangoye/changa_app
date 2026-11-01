import 'package:changa_app/core/constants/app_constants.dart';

/// How the household is doing, from the 0 to 100 Harmony Score.
enum HarmonyTier {
  needsAttention,
  steady,
  thriving;

  static HarmonyTier fromValue(int value) {
    if (value >= AppConstants.harmonyThrivingMin) return HarmonyTier.thriving;
    if (value >= AppConstants.harmonySteadyMin) return HarmonyTier.steady;
    return HarmonyTier.needsAttention;
  }

  String get label => switch (this) {
    HarmonyTier.needsAttention => 'Needs attention',
    HarmonyTier.steady => 'Steady',
    HarmonyTier.thriving => 'Thriving',
  };
}
