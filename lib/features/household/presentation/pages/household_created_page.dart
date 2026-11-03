// Household Created Screen: PIN display, copy, and share

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:changa_app/core/router/route_names.dart';
import 'package:changa_app/core/theme/app_colors.dart';
import 'package:changa_app/core/theme/app_spacing.dart';
import 'package:changa_app/core/widgets/app_snackbar.dart';
import 'package:changa_app/core/widgets/primary_button.dart';
import 'package:changa_app/features/household/domain/entities/household.dart';
import 'package:changa_app/features/household/presentation/cubit/household_cubit.dart';
import 'package:changa_app/features/household/presentation/widgets/household_type_chips.dart';
import 'package:changa_app/features/household/presentation/widgets/pin_card.dart';

class HouseholdCreatedPage extends StatelessWidget {
  final Household? household;
  final Future<void> Function(String text)? onShare;

  const HouseholdCreatedPage({super.key, this.household, this.onShare});

  /// Builds the exact share text required by the B8 specification:
  /// `"Join my household on Changa with PIN 482 916"`
  static String buildShareMessage(String rawPin) {
    final formattedPin = PinCard.formatPinWithSpace(rawPin);
    return 'Join my household on Changa with PIN $formattedPin';
  }

  Household? _resolveHousehold(BuildContext context) {
    if (household != null) return household;

    try {
      final extra = GoRouterState.of(context).extra;
      if (extra is Household) return extra;
    } catch (_) {
      // Ignored when rendered outside GoRouter
    }

    try {
      final fromContext = context.watch<HouseholdCubit>().state.household;
      if (fromContext != null) return fromContext;
    } catch (_) {
      // Ignored when HouseholdCubit is not in the widget tree
    }

    if (GetIt.instance.isRegistered<HouseholdCubit>()) {
      return GetIt.instance<HouseholdCubit>().state.household;
    }

    return null;
  }

  Future<void> _shareInvite(String pin) async {
    final message = buildShareMessage(pin);
    if (onShare != null) {
      await onShare!(message);
      return;
    }
    // ignore: deprecated_member_use
    await Share.share(message);
  }

  Future<void> _copyInviteMessage(BuildContext context, String pin) async {
    final message = buildShareMessage(pin);
    await Clipboard.setData(ClipboardData(text: message));
    if (context.mounted) {
      AppSnackbar.success(context, 'Invite message copied to clipboard!');
    }
  }

  void _goToDashboard(BuildContext context) {
    try {
      context.goNamed(RouteNames.dashboard);
    } catch (_) {
      // Ignored when tested outside GoRouter
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeHousehold = _resolveHousehold(context);
    final pin = activeHousehold?.pin ?? '482916';
    final name = activeHousehold?.name ?? 'Your Household';
    final typeLabel = HouseholdTypeChips.labelFor(
      activeHousehold?.type ?? HouseholdType.apartment,
    );
    final expectedCount = activeHousehold?.expectedMembers ?? 4;

    return Scaffold(
      backgroundColor: AppColors.sherwoodGreen,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Dark Green Top Banner
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xxl,
                vertical: AppSpacing.xxl,
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: AppColors.leafGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: AppColors.white,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Text(
                    'Your household is ready!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Share this PIN with your roommates so\nthey can join',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppColors.ginFizz.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),

            // Cream Bottom Sheet Card
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.ginFizz,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xxl,
                    AppSpacing.xxl,
                    AppSpacing.xxl,
                    AppSpacing.xxxl,
                  ),
                  child: Column(
                    children: [
                      // PIN Card
                      PinCard(pin: pin),
                      const SizedBox(height: AppSpacing.lg),

                      // Summary Pill ("Kigali Nest · Apartment · 4 members")
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.athsSpecial,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.home_rounded,
                              size: 16,
                              color: AppColors.sherwoodGreen,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                '$name · $typeLabel · $expectedCount members',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.sherwoodGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      // INVITE VIA Section
                      const Text(
                        'INVITE VIA',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                          color: AppColors.edward,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _InviteChannelButton(
                            icon: Icons.chat_bubble_outline_rounded,
                            label: 'WhatsApp',
                            backgroundColor: AppColors.opal.withValues(
                              alpha: 0.3,
                            ),
                            iconColor: AppColors.leafGreen,
                            onTap: () => _shareInvite(pin),
                          ),
                          const SizedBox(width: AppSpacing.xxl),
                          _InviteChannelButton(
                            icon: Icons.sms_outlined,
                            label: 'SMS',
                            backgroundColor: AppColors.edward.withValues(
                              alpha: 0.2,
                            ),
                            iconColor: AppColors.sherwoodGreen,
                            onTap: () => _shareInvite(pin),
                          ),
                          const SizedBox(width: AppSpacing.xxl),
                          _InviteChannelButton(
                            icon: Icons.share_outlined,
                            label: 'Share',
                            backgroundColor: AppColors.sunglo.withValues(
                              alpha: 0.15,
                            ),
                            iconColor: AppColors.sunglo,
                            onTap: () => _shareInvite(pin),
                          ),
                          const SizedBox(width: AppSpacing.xxl),
                          _InviteChannelButton(
                            icon: Icons.link_rounded,
                            label: 'Copy Link',
                            backgroundColor: AppColors.sunglo.withValues(
                              alpha: 0.15,
                            ),
                            iconColor: AppColors.sunglo,
                            onTap: () => _copyInviteMessage(context, pin),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxxl),

                      // Go to Dashboard
                      PrimaryButton(
                        text: 'Go to Dashboard',
                        onPressed: () => _goToDashboard(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InviteChannelButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _InviteChannelButton({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.sherwoodGreen,
            ),
          ),
        ],
      ),
    );
  }
}
