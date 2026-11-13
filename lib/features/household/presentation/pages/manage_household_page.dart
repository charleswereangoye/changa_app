// Manage Household Screen: member list, PIN regenerate, admin transfer

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:changa_app/core/router/route_names.dart';
import 'package:changa_app/core/theme/app_colors.dart';
import 'package:changa_app/core/theme/app_spacing.dart';
import 'package:changa_app/core/widgets/app_snackbar.dart';
import 'package:changa_app/features/household/domain/entities/household.dart';
import 'package:changa_app/features/household/domain/entities/member.dart';
import 'package:changa_app/features/household/presentation/cubit/household_cubit.dart';
import 'package:changa_app/features/household/presentation/cubit/manage_household_cubit.dart';
import 'package:changa_app/features/household/presentation/widgets/household_type_chips.dart';
import 'package:changa_app/features/household/presentation/widgets/member_actions_sheet.dart';
import 'package:changa_app/features/household/presentation/widgets/member_tile.dart';
import 'package:changa_app/features/household/presentation/widgets/pin_card.dart';

class ManageHouseholdPage extends StatefulWidget {
  final ManageHouseholdCubit? cubit;
  final String? householdId;
  final String? currentUid;

  const ManageHouseholdPage({
    super.key,
    this.cubit,
    this.householdId,
    this.currentUid,
  });

  @override
  State<ManageHouseholdPage> createState() => _ManageHouseholdPageState();
}

class _ManageHouseholdPageState extends State<ManageHouseholdPage> {
  static final NumberFormat _numberFormat = NumberFormat('#,###', 'en_US');

  late final ManageHouseholdCubit _cubit;
  late final bool _ownsCubit;

  @override
  void initState() {
    super.initState();
    if (widget.cubit != null) {
      _cubit = widget.cubit!;
      _ownsCubit = false;
    } else if (GetIt.instance.isRegistered<ManageHouseholdCubit>()) {
      _cubit = GetIt.instance<ManageHouseholdCubit>();
      _ownsCubit = true;
    } else {
      final globalCubit = GetIt.instance.isRegistered<HouseholdCubit>()
          ? GetIt.instance<HouseholdCubit>()
          : null;
      _cubit = ManageHouseholdCubit(householdCubit: globalCubit);
      _ownsCubit = true;
    }

    _initializeCubit();
  }

  void _initializeCubit() {
    if (_cubit.state is ManageHouseholdStateLoaded &&
        widget.householdId == null) {
      return;
    }

    HouseholdCubit? contextHouseholdCubit;
    try {
      contextHouseholdCubit = context.read<HouseholdCubit>();
    } catch (_) {
      if (GetIt.instance.isRegistered<HouseholdCubit>()) {
        contextHouseholdCubit = GetIt.instance<HouseholdCubit>();
      }
    }

    final globalState = contextHouseholdCubit?.state;
    if (globalState is HouseholdStateLoaded &&
        _cubit.state is! ManageHouseholdStateLoaded) {
      _cubit.seedState(
        household: globalState.household,
        members: globalState.members,
        memberNames: globalState.memberNames,
        currentUid:
            widget.currentUid ??
            globalState.currentMember?.uid ??
            globalState.household.adminUid,
      );
    }

    final targetId =
        widget.householdId ??
        _cubit.state.household?.id ??
        globalState?.household?.id;
    if (targetId != null && targetId.isNotEmpty) {
      _cubit.load(householdId: targetId, currentUid: widget.currentUid);
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
      } else {
        context.goNamed(RouteNames.dashboard);
      }
    } catch (_) {
      Navigator.of(context).maybePop();
    }
  }

  void _openInvitePage(BuildContext context, Household household) {
    try {
      context.pushNamed(RouteNames.householdCreated, extra: household);
    } catch (_) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(body: Center(child: Text(household.pin))),
        ),
      );
    }
  }

  Future<void> _showRegeneratePinDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _HouseholdConfirmDialog(
        title: 'Regenerate PIN?',
        message: 'Anyone with the old PIN will no longer be able to join. Current members keep their access.',
        confirmText: 'Regenerate',
        cancelText: 'Cancel',
        onConfirm: () => Navigator.of(dialogContext).pop(true),
        onCancel: () => Navigator.of(dialogContext).pop(false),
      ),
    );

    if (confirmed == true && mounted) {
      await _cubit.regeneratePin();
    }
  }

  Future<void> _showTransferAdminDialog(
    BuildContext context,
    Member member,
    String memberName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _HouseholdConfirmDialog(
        title: 'Transfer admin',
        message:
            'Make $memberName the new household admin? You will become a regular member.',
        confirmText: 'Transfer',
        cancelText: 'Cancel',
        onConfirm: () => Navigator.of(dialogContext).pop(true),
        onCancel: () => Navigator.of(dialogContext).pop(false),
      ),
    );

    if (confirmed == true && mounted) {
      await _cubit.transferAdmin(member.uid);
    }
  }

  Future<void> _showRemoveMemberDialog(
    BuildContext context,
    Member member,
    String memberName,
  ) async {
    final balance = await _cubit.fetchOutstandingBalance(member.uid);
    if (!context.mounted) return;

    final hasBalance = balance > 0;
    final formattedBalance = _numberFormat.format(balance);
    final bodyText = hasBalance
        ? 'Remove $memberName from this household?\n\nOutstanding balance: $formattedBalance RWF'
        : 'Remove $memberName from this household? Their pending chores will be reassigned to the admin.';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _HouseholdConfirmDialog(
        title: 'Remove from household',
        message: bodyText,
        confirmText: 'Remove anyway',
        cancelText: 'Cancel',
        isDestructive: true,
        onConfirm: () => Navigator.of(dialogContext).pop(true),
        onCancel: () => Navigator.of(dialogContext).pop(false),
      ),
    );

    if (confirmed == true && mounted) {
      await _cubit.removeMember(member.uid);
    }
  }

  void _openMemberActions(
    BuildContext context,
    ManageHouseholdState state,
    Member member,
  ) {
    final name = state.displayNameFor(member.uid);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => MemberActionsSheet(
        memberName: name,
        isAdmin: state.isAdmin,
        onTransferAdmin: () => _showTransferAdminDialog(context, member, name),
        onRemoveMember: () => _showRemoveMemberDialog(context, member, name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ManageHouseholdCubit>.value(
      value: _cubit,
      child: BlocConsumer<ManageHouseholdCubit, ManageHouseholdState>(
        listener: (context, state) {
          if (state.actionMessage != null && state.actionMessage!.isNotEmpty) {
            AppSnackbar.success(context, state.actionMessage!);
            _cubit.clearFeedback();
          } else if (state.errorMessage != null &&
              state.errorMessage!.isNotEmpty &&
              state is ManageHouseholdStateLoaded) {
            AppSnackbar.error(context, state.errorMessage!);
            _cubit.clearFeedback();
          }
        },
        builder: (context, state) {
          final household = state.household;

          return Scaffold(
            backgroundColor: AppColors.ginFizz,
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final horizontalPadding = constraints.maxWidth < 360
                      ? AppSpacing.md
                      : AppSpacing.xxl;

                  if (state is ManageHouseholdStateLoading ||
                      state is ManageHouseholdStateInitial) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (household == null) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(horizontalPadding),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              state.errorMessage ??
                                  'Household details could not be loaded.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                color: AppColors.sherwoodGreen,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            OutlinedButton(
                              onPressed: () => _cubit.load(
                                householdId: widget.householdId,
                                currentUid: widget.currentUid,
                              ),
                              child: const Text('Try again'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final members = state.members;
                  final memberCount = members.isNotEmpty
                      ? members.length
                      : household.expectedMembers;
                  final formattedPin =
                      PinCard.formatPinWithSpace(household.pin).isNotEmpty
                      ? PinCard.formatPinWithSpace(household.pin)
                      : household.pin;

                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: AppSpacing.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Header Bar
                        Row(
                          children: [
                            Material(
                              color: AppColors.white,
                              shape: const CircleBorder(),
                              elevation: 1,
                              shadowColor: AppColors.black.withValues(
                                alpha: 0.08,
                              ),
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
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Manage Household',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.sherwoodGreen,
                                    ),
                                  ),
                                  Text(
                                    household.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.edward,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Summary Card (Name, Type & Member count, PIN + Regenerate)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.black.withValues(alpha: 0.04),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.opal.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(14),
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
                                      household.name,
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.sherwoodGreen,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${HouseholdTypeChips.labelFor(household.type)} · '
                                      '$memberCount ${memberCount == 1 ? 'member' : 'members'}',
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 12,
                                        color: AppColors.edward,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (state.isAdmin)
                                IconButton(
                                  key: const Key('summary-regenerate-pin-btn'),
                                  tooltip: 'Regenerate PIN',
                                  onPressed: state.isSubmitting
                                      ? null
                                      : () => _showRegeneratePinDialog(context),
                                  style: IconButton.styleFrom(
                                    backgroundColor: AppColors.athsSpecial,
                                  ),
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                    color: AppColors.sherwoodGreen,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Members Section Header
                        Text(
                          'MEMBERS (${members.length})',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                            color: AppColors.sherwoodGreen,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        // Members List
                        for (final member in members) ...[
                          MemberTile(
                            member: member,
                            displayName: state.displayNameFor(member.uid),
                            harmonyScore: state.harmonyScores[member.uid],
                            isAdminRole:
                                member.role == MemberRole.admin ||
                                member.uid == household.adminUid,
                            showMenu:
                                state.isAdmin &&
                                member.uid != household.adminUid,
                            enabled: !state.isSubmitting,
                            onMorePressed: () =>
                                _openMemberActions(context, state, member),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ],

                        const SizedBox(height: AppSpacing.lg),
                        const Text(
                          'INVITE',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                            color: AppColors.sherwoodGreen,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        // Dark Green PIN & Invite Footer Card (Figma match)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          decoration: BoxDecoration(
                            color: AppColors.sherwoodGreen,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Household PIN',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 11,
                                            color: AppColors.ginFizz.withValues(
                                              alpha: 0.75,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          formattedPin,
                                          key: const Key('household-pin-text'),
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 26,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1.2,
                                            color: AppColors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  ElevatedButton(
                                    key: const Key('invite-new-member-btn'),
                                    onPressed: () =>
                                        _openInvitePage(context, household),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.leafGreen,
                                      foregroundColor: AppColors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.lg,
                                        vertical: AppSpacing.md,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: const Text(
                                      'Invite new member',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (state.isAdmin) ...[
                                const SizedBox(height: AppSpacing.sm),
                                TextButton.icon(
                                  key: const Key('regenerate-pin-button'),
                                  onPressed: state.isSubmitting
                                      ? null
                                      : () => _showRegeneratePinDialog(context),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.lightGreen,
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(0, 36),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  icon: const Icon(
                                    Icons.refresh_rounded,
                                    size: 16,
                                  ),
                                  label: const Text(
                                    'Regenerate PIN',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],
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

class _HouseholdConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final bool isDestructive;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _HouseholdConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmText,
    required this.cancelText,
    this.isDestructive = false,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.ginFizz,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.sherwoodGreen,
        ),
      ),
      content: Text(
        message,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          color: AppColors.sherwoodGreen,
        ),
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: Text(
            cancelText,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              color: AppColors.sherwoodGreen,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: isDestructive
                ? AppColors.sunglo
                : AppColors.sherwoodGreen,
            foregroundColor: AppColors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            confirmText,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
