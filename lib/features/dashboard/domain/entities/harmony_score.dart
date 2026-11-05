import 'package:equatable/equatable.dart';

import 'package:changa_app/core/enums/harmony_tier.dart';

// Re-exported so existing imports of this file keep seeing HarmonyTier.
export 'package:changa_app/core/enums/harmony_tier.dart';

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
