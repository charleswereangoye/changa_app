import 'package:equatable/equatable.dart';

import 'package:changa_app/core/constants/app_constants.dart';

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

class HarmonyScore extends Equatable {
  const HarmonyScore({
    required this.value,
    required this.tier,
    this.choreScore,
    this.paymentScore,
  });

  /// 0 to 100, always about the household and never one person.
  final int value;
  final HarmonyTier tier;
  final int? choreScore;
  final int? paymentScore;

  @override
  List<Object?> get props => [value, tier, choreScore, paymentScore];
}
