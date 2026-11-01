import 'package:flutter_test/flutter_test.dart';

import 'package:changa_app/core/enums/harmony_tier.dart';
import 'package:changa_app/core/theme/app_colors.dart';
import 'package:changa_app/core/theme/app_theme.dart';
import 'package:changa_app/core/widgets/progress_ring.dart';

void main() {
  final scheme = AppTheme.lightTheme.colorScheme;

  group('credit badge colours', () {
    test('use the cream card fill with dark green text', () {
      expect(scheme.primaryContainer, AppColors.athsSpecial);
      expect(scheme.onPrimaryContainer, AppColors.sherwoodGreen);
    });
  });

  group('harmony ring colours', () {
    test('each tier gets its own palette colour', () {
      expect(ProgressRing.tierColor(scheme, 90), AppColors.sherwoodGreen);
      expect(ProgressRing.tierColor(scheme, 60), AppColors.goldSand);
      expect(ProgressRing.tierColor(scheme, 20), AppColors.sunglo);
    });

    test('the three tiers never share a colour', () {
      final colours = {
        for (final tier in HarmonyTier.values)
          ProgressRing.tierColor(scheme, switch (tier) {
            HarmonyTier.thriving => 90,
            HarmonyTier.steady => 60,
            HarmonyTier.needsAttention => 20,
          }),
      };
      expect(colours.length, HarmonyTier.values.length);
    });

    test('tier boundaries pick the right colour', () {
      expect(ProgressRing.tierColor(scheme, 49), AppColors.sunglo);
      expect(ProgressRing.tierColor(scheme, 50), AppColors.goldSand);
      expect(ProgressRing.tierColor(scheme, 79), AppColors.goldSand);
      expect(ProgressRing.tierColor(scheme, 80), AppColors.sherwoodGreen);
    });

    test('no score yet uses the neutral outline', () {
      expect(ProgressRing.tierColor(scheme, null), AppColors.edward);
    });
  });
}
