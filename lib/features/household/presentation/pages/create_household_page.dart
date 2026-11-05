// Create Household Screen: name, type, roommate stepper

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:changa_app/core/router/route_names.dart';
import 'package:changa_app/core/theme/app_colors.dart';
import 'package:changa_app/core/theme/app_spacing.dart';
import 'package:changa_app/core/theme/app_text_styles.dart';
import 'package:changa_app/core/widgets/app_snackbar.dart';
import 'package:changa_app/core/widgets/app_text_field.dart';
import 'package:changa_app/core/widgets/primary_button.dart';
import 'package:changa_app/features/household/presentation/cubit/create_household_cubit.dart';
import 'package:changa_app/features/household/presentation/cubit/household_cubit.dart';
import 'package:changa_app/features/household/presentation/widgets/household_type_chips.dart';

class CreateHouseholdPage extends StatefulWidget {
  final CreateHouseholdCubit? cubit;

  const CreateHouseholdPage({super.key, this.cubit});

  @override
  State<CreateHouseholdPage> createState() => _CreateHouseholdPageState();
}

class _CreateHouseholdPageState extends State<CreateHouseholdPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  late final CreateHouseholdCubit _cubit;
  late final bool _ownsCubit;

  @override
  void initState() {
    super.initState();
    if (widget.cubit != null) {
      _cubit = widget.cubit!;
      _ownsCubit = false;
    } else if (GetIt.instance.isRegistered<CreateHouseholdCubit>()) {
      _cubit = GetIt.instance<CreateHouseholdCubit>();
      _ownsCubit = true;
    } else {
      _cubit = CreateHouseholdCubit();
      _ownsCubit = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    if (_ownsCubit) {
      _cubit.close();
    }
    super.dispose();
  }

  void _handleCreatePressed() {
    if (_cubit.state.isSubmitting) return;
    final isFormValid = _formKey.currentState?.validate() ?? false;
    if (!isFormValid) return;
    _cubit.submit(name: _nameController.text);
  }

  void _handleBack(BuildContext context) {
    try {
      if (context.canPop()) {
        context.pop();
      } else {
        context.goNamed(RouteNames.login);
      }
    } catch (_) {
      // Safe fallback when tested outside GoRouter
    }
  }

  void _handleGoToJoin(BuildContext context) {
    try {
      context.pushNamed(RouteNames.joinHousehold);
    } catch (_) {
      // Safe fallback when tested outside GoRouter
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CreateHouseholdCubit>.value(
      value: _cubit,
      child: BlocConsumer<CreateHouseholdCubit, CreateHouseholdState>(
        listener: (context, state) {
          if (state is CreateHouseholdStateSuccess) {
            try {
              context.read<HouseholdCubit>().setHousehold(state.household);
            } catch (_) {
              if (GetIt.instance.isRegistered<HouseholdCubit>()) {
                GetIt.instance<HouseholdCubit>().setHousehold(state.household);
              }
            }
            try {
              context.goNamed(
                RouteNames.householdCreated,
                extra: state.household,
              );
            } catch (_) {
              // Safe fallback when pumped without GoRouter in widget tests
            }
          } else if (state is CreateHouseholdStateFailure) {
            AppSnackbar.error(context, state.message);
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: AppColors.ginFizz,
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final horizontalPadding = constraints.maxWidth < 360
                      ? AppSpacing.md
                      : AppSpacing.xxl;

                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: AppSpacing.md,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _BackCircleButton(
                            onPressed: () => _handleBack(context),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          const Text(
                            'Set up your household',
                            style: AppTextStyles.heading2,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Give your home a name and invite your roommates',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.edward,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.md,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.athsSpecial,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.sherwoodGreen.withValues(
                                  alpha: 0.06,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: AppColors.leafGreen.withValues(
                                      alpha: 0.15,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.home_rounded,
                                    size: 18,
                                    color: AppColors.leafGreen,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                const Flexible(
                                  child: Text(
                                    'Build your shared space',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.sherwoodGreen,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            label: 'Household Name',
                            hintText: 'e.g. Kigali Nest',
                            controller: _nameController,
                            enabled: !state.isSubmitting,
                            textInputAction: TextInputAction.done,
                            prefixIcon: const Icon(
                              Icons.home_outlined,
                              color: AppColors.edward,
                              size: 20,
                            ),
                            validator: CreateHouseholdCubit.validateName,
                            onChanged: _cubit.nameChanged,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          const Text(
                            'Household Type',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.sherwoodGreen,
                            ),
                          ),
                          const SizedBox(height: 4),
                          HouseholdTypeChips(
                            selectedType: state.type,
                            enabled: !state.isSubmitting,
                            onSelected: _cubit.typeChanged,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          const Text(
                            'Number of Roommates',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.sherwoodGreen,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _RoommatesStepper(
                            count: state.expectedMembers,
                            enabled: !state.isSubmitting,
                            onDecrement: _cubit.decrementMembers,
                            onIncrement: _cubit.incrementMembers,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          PrimaryButton(
                            text: 'Create Household',
                            isLoading: state.isSubmitting,
                            onPressed: _handleCreatePressed,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton(
                              onPressed: state.isSubmitting
                                  ? null
                                  : () => _handleGoToJoin(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.sherwoodGreen,
                                side: const BorderSide(
                                  color: AppColors.sherwoodGreen,
                                  width: 1.2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Join an existing household instead',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.sherwoodGreen,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RoommatesStepper extends StatelessWidget {
  final int count;
  final bool enabled;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _RoommatesStepper({
    required this.count,
    required this.enabled,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    final canDecrement = enabled && count > CreateHouseholdCubit.minRoommates;
    final canIncrement = enabled && count < CreateHouseholdCubit.maxRoommates;

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.sherwoodGreen.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _StepperIconButton(
            icon: Icons.remove,
            backgroundColor: AppColors.athsSpecial,
            iconColor: AppColors.sherwoodGreen,
            onPressed: canDecrement ? onDecrement : null,
            semanticLabel: 'Decrease roommates',
          ),
          Text(
            '$count',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.sherwoodGreen,
            ),
          ),
          _StepperIconButton(
            icon: Icons.add,
            backgroundColor: AppColors.lightGreen,
            iconColor: AppColors.white,
            onPressed: canIncrement ? onIncrement : null,
            semanticLabel: 'Increase roommates',
          ),
        ],
      ),
    );
  }
}

class _StepperIconButton extends StatelessWidget {
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback? onPressed;
  final String semanticLabel;

  const _StepperIconButton({
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.onPressed,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: isEnabled,
      label: semanticLabel,
      child: Material(
        color: isEnabled
            ? backgroundColor
            : backgroundColor.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 32,
            height: 32,
            child: Icon(
              icon,
              size: 16,
              color: isEnabled ? iconColor : iconColor.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}

class _BackCircleButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _BackCircleButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      shape: const CircleBorder(),
      elevation: 1,
      shadowColor: AppColors.black.withValues(alpha: 0.08),
      child: InkWell(
        onTap: onPressed,
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
    );
  }
}
