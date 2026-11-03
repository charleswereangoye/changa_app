// Join Household Screen: enter 6-digit PIN and join

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:changa_app/core/router/route_names.dart';
import 'package:changa_app/core/theme/app_colors.dart';
import 'package:changa_app/core/theme/app_spacing.dart';
import 'package:changa_app/core/theme/app_text_styles.dart';
import 'package:changa_app/core/widgets/app_snackbar.dart';
import 'package:changa_app/core/widgets/pin_input.dart';
import 'package:changa_app/core/widgets/primary_button.dart';
import 'package:changa_app/features/household/domain/entities/household_preview.dart';
import 'package:changa_app/features/household/presentation/cubit/household_cubit.dart';
import 'package:changa_app/features/household/presentation/cubit/join_household_cubit.dart';

class JoinHouseholdPage extends StatefulWidget {
  final JoinHouseholdCubit? cubit;

  const JoinHouseholdPage({super.key, this.cubit});

  @override
  State<JoinHouseholdPage> createState() => _JoinHouseholdPageState();
}

class _JoinHouseholdPageState extends State<JoinHouseholdPage> {
  late final JoinHouseholdCubit _cubit;
  late final bool _ownsCubit;

  @override
  void initState() {
    super.initState();
    if (widget.cubit != null) {
      _cubit = widget.cubit!;
      _ownsCubit = false;
    } else if (GetIt.instance.isRegistered<JoinHouseholdCubit>()) {
      _cubit = GetIt.instance<JoinHouseholdCubit>();
      _ownsCubit = true;
    } else {
      _cubit = JoinHouseholdCubit();
      _ownsCubit = true;
    }
  }

  @override
  void dispose() {
    if (_ownsCubit) {
      _cubit.close();
    }
    super.dispose();
  }

  void _handleBack(BuildContext context) {
    try {
      if (context.canPop()) {
        context.pop();
      }
    } catch (_) {
      // Safe fallback when tested outside GoRouter
    }
  }

  void _handleGoToCreate(BuildContext context) {
    try {
      context.goNamed(RouteNames.createHousehold);
    } catch (_) {
      // Safe fallback when tested outside GoRouter
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<JoinHouseholdCubit>.value(
      value: _cubit,
      child: BlocConsumer<JoinHouseholdCubit, JoinHouseholdState>(
        listener: (context, state) {
          if (state is JoinHouseholdStateSuccess) {
            try {
              context.read<HouseholdCubit>().setHousehold(state.household);
            } catch (_) {
              if (GetIt.instance.isRegistered<HouseholdCubit>()) {
                GetIt.instance<HouseholdCubit>().setHousehold(state.household);
              }
            }
            try {
              context.goNamed(RouteNames.dashboard);
            } catch (_) {
              // Ignored when tested outside GoRouter
            }
          } else if (state is JoinHouseholdStateError) {
            AppSnackbar.error(context, state.message);
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: AppColors.ginFizz,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl,
                  vertical: AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back Circle Button
                    Material(
                      color: AppColors.white,
                      shape: const CircleBorder(),
                      elevation: 1,
                      shadowColor: AppColors.black.withValues(alpha: 0.08),
                      child: InkWell(
                        onTap: () => _handleBack(context),
                        customBorder: const CircleBorder(),
                        child: const SizedBox(
                          width: 40,
                          height: 40,
                          child: Icon(
                            Icons.arrow_back_rounded,
                            size: 20,
                            color: AppColors.sherwoodGreen,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Title & Subtitle
                    const Text(
                      'Join your household',
                      style: AppTextStyles.heading2,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Ask a roommate for the 6-digit household PIN',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.edward,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // 6-digit PinInput widget (B4)
                    PinInput(
                      hasError: state.hasError,
                      onCompleted: _cubit.onPinCompleted,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Caption or Polite Error Text
                    Center(
                      child: Text(
                        state.hasError
                            ? (state.errorMessage ??
                                  'No household found with that PIN.')
                            : 'Enter the PIN shared by your roommate',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: state.hasError
                              ? FontWeight.w500
                              : FontWeight.w400,
                          color: state.hasError
                              ? AppColors.sunglo
                              : AppColors.edward,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // Loading or Preview Card
                    if (state.isPreviewLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.xxl),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (state.preview != null)
                      _HouseholdPreviewCard(preview: state.preview!),

                    const Spacer(),

                    // Join Household Button
                    PrimaryButton(
                      text: 'Join Household',
                      isLoading: state.isJoining,
                      onPressed: state.canJoin
                          ? () => _cubit.joinHousehold()
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Bottom Link: "Don't have a PIN? Create your own household"
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(
                            "Don't have a PIN? ",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: AppColors.edward,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _handleGoToCreate(context),
                            child: const Text(
                              'Create your own household',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.leafGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HouseholdPreviewCard extends StatelessWidget {
  final HouseholdPreview preview;

  const _HouseholdPreviewCard({required this.preview});

  @override
  Widget build(BuildContext context) {
    final count = preview.memberCount;
    final memberLabel = count == 1 ? '1 member' : '$count members';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.opal.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.home_rounded,
                  color: AppColors.sherwoodGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      preview.name,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.sherwoodGreen,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      memberLabel,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppColors.edward,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (count > 0) ...[
            const SizedBox(height: AppSpacing.md),
            _OverlappingMemberDots(memberCount: count),
          ],
        ],
      ),
    );
  }
}

class _OverlappingMemberDots extends StatelessWidget {
  final int memberCount;

  const _OverlappingMemberDots({required this.memberCount});

  @override
  Widget build(BuildContext context) {
    const circleColors = [AppColors.pewter, AppColors.goldSand, AppColors.opal];
    final visibleDots = memberCount.clamp(0, 3);
    final remaining = memberCount - visibleDots;
    final totalItems = visibleDots + (remaining > 0 ? 1 : 0);

    return SizedBox(
      height: 28,
      width: totalItems * 22.0 + 8,
      child: Stack(
        children: [
          for (var i = 0; i < visibleDots; i++)
            Positioned(
              left: i * 18.0,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: circleColors[i % circleColors.length],
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 2),
                ),
              ),
            ),
          if (remaining > 0)
            Positioned(
              left: visibleDots * 18.0,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.lightGreen,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    '+$remaining',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
