// Owner: A - Person A (Foundation, Authentication, Profile)
// Screen: Profile Screen: user info, stats, settings options matching Figma specifications

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../injection_container.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../chores/domain/entities/chore.dart';
import '../../../chores/domain/repositories/chore_repository.dart';
import '../../../dashboard/presentation/cubit/dashboard_cubit.dart';
import '../../../household/domain/usecases/leave_household.dart';
import '../../../household/presentation/cubit/household_cubit.dart';
import '../cubit/profile_cubit.dart';
import '../widgets/profile_header.dart';
import '../widgets/settings_tile.dart';

/// Main Profile screen displaying member identity, stats row, and grouped settings cards.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProfileCubit>(
      create: (context) {
        final cubit = sl.isRegistered<ProfileCubit>()
            ? sl<ProfileCubit>()
            : ProfileCubit();
        final currentUid = context.read<AuthCubit>().state.user?.uid;
        if (currentUid != null && currentUid.isNotEmpty) {
          cubit.loadProfile(currentUid);
        }
        return cubit;
      },
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final householdState = context.watch<HouseholdCubit>().state;
    final profileState = context.watch<ProfileCubit>().state;

    // Resolve user from ProfileCubit if loaded, otherwise from global AuthCubit
    final AppUser? user = profileState is ProfileStateLoaded
        ? profileState.user
        : authState.user;

    final fallbackUser =
        user ??
        AppUser(
          uid: '',
          fullName: 'Changa Member',
          email: '',
          phone: '',
          createdAt: DateTime.fromMillisecondsSinceEpoch(0),
        );

    final household = householdState.household;
    final joinedAt = householdState.currentMember?.joinedAt ?? user?.createdAt;
    final credits = householdState.myCredits;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF072B28) : AppColors.white;
    final cardBorder = isDark
        ? Border.all(color: const Color(0xFF0F3E3A))
        : null;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                color: isDark ? AppColors.ginFizz : AppColors.sherwoodGreen,
                onPressed: () => context.pop(),
              )
            : null,
        title: Text(
          'Profile',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.ginFizz : AppColors.sherwoodGreen,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            color: isDark ? AppColors.ginFizz : AppColors.sherwoodGreen,
            tooltip: 'Preferences',
            onPressed: () => context.pushNamed(RouteNames.preferences),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile Header with Avatar and Stats
              if (household != null && sl.isRegistered<ChoreRepository>())
                StreamBuilder<List<Chore>>(
                  stream: sl<ChoreRepository>().watchAllChores(household.id),
                  builder: (context, snapshot) {
                    final chores = snapshot.data ?? const [];
                    final choresDone = chores
                        .where(
                          (c) =>
                              c.status == ChoreStatus.done &&
                              c.assignedToUid == fallbackUser.uid,
                        )
                        .length;

                    final dynamicScore = sl.isRegistered<DashboardCubit>()
                        ? sl<DashboardCubit>().state.harmony?.value
                        : null;

                    return ProfileHeader(
                      user: fallbackUser,
                      householdName: household.name,
                      joinedAt: joinedAt,
                      harmonyScore: dynamicScore,
                      credits: credits,
                      choresDone: choresDone,
                    );
                  },
                )
              else
                ProfileHeader(
                  user: fallbackUser,
                  householdName: household?.name,
                  joinedAt: joinedAt,
                  credits: credits,
                  choresDone: 0,
                ),

              const SizedBox(height: 24),

              // Account Section
              const SectionHeader(title: 'Account'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: cardBorder,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      SettingsTile(
                        key: const Key('profile-tile-edit-profile'),
                        title: 'Edit Profile',
                        subtitle: 'Update your name and phone number',
                        icon: Icons.person_outline_rounded,
                        onTap: () => context.pushNamed(RouteNames.editProfile),
                      ),
                      SettingsTile(
                        key: const Key('profile-tile-preferences'),
                        title: 'Notification Preferences',
                        subtitle: 'Manage nudges, chores & alerts',
                        icon: Icons.notifications_none_rounded,
                        onTap: () => context.pushNamed(RouteNames.preferences),
                      ),
                      SettingsTile(
                        key: const Key('profile-tile-payment-methods'),
                        title: 'Payment Methods',
                        subtitle: 'Default settlement options',
                        icon: Icons.credit_card_rounded,
                        showDivider: false,
                        onTap: () =>
                            context.pushNamed(RouteNames.paymentMethods),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Household Section
              const SectionHeader(title: 'Household'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: cardBorder,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      SettingsTile(
                        key: const Key('profile-tile-manage-household'),
                        title: 'Manage Household',
                        subtitle: household != null
                            ? '${household.name} (${householdState.members.length} members)'
                            : 'Set up or join a household',
                        badgeText: householdState.isAdmin ? 'Admin' : null,
                        icon: Icons.home_work_outlined,
                        showDivider: household != null,
                        onTap: () {
                          if (household != null) {
                            context.pushNamed(RouteNames.manageHousehold);
                          } else {
                            context.pushNamed(RouteNames.createHousehold);
                          }
                        },
                      ),
                      if (household != null)
                        SettingsTile(
                          key: const Key('profile-tile-leave-household'),
                          title: 'Leave Household',
                          subtitle: 'Exit your current household',
                          icon: Icons.exit_to_app_rounded,
                          isDestructive: true,
                          showDivider: false,
                          onTap: () =>
                              _handleLeaveHousehold(context, householdState),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Support Section
              const SectionHeader(title: 'Support'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: cardBorder,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      SettingsTile(
                        key: const Key('profile-tile-help'),
                        title: 'Help & FAQ',
                        subtitle: 'Learn how Changa works & contact support',
                        icon: Icons.help_outline_rounded,
                        onTap: () => _showHelpSheet(context),
                      ),
                      SettingsTile(
                        key: const Key('profile-tile-logout'),
                        title: 'Log Out',
                        subtitle: 'Sign out of your Changa account',
                        icon: Icons.logout_rounded,
                        isDestructive: true,
                        showDivider: false,
                        onTap: () => _handleSignOut(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLeaveHousehold(
    BuildContext context,
    HouseholdState state,
  ) async {
    final household = state.household;
    if (household == null) return;

    if (state.isAdmin) {
      await showDialog<void>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Cannot Leave Household',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.sherwoodGreen,
            ),
          ),
          content: const Text(
            'As the household administrator, you cannot leave directly. Please transfer admin rights to another member first in Manage Household.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: AppColors.edward,
              height: 1.5,
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.sherwoodGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Leave Household',
      message:
          'Are you sure you want to leave ${household.name}? You will lose access to shared expenses, chores and household balances.',
      confirmLabel: 'Leave',
      isDestructive: true,
    );

    if (confirmed == true && context.mounted) {
      if (sl.isRegistered<LeaveHousehold>()) {
        final result = await sl<LeaveHousehold>()(household.id);
        if (result.isSuccess && context.mounted) {
          context.read<HouseholdCubit>().clearHousehold();
          AppSnackbar.success(context, 'You have left ${household.name}.');
        } else if (context.mounted) {
          AppSnackbar.error(
            context,
            result.failureOrNull?.message ?? 'Failed to leave household.',
          );
        }
      }
    }
  }

  Future<void> _handleSignOut(BuildContext context) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Log Out',
      message: 'Are you sure you want to log out of your Changa account?',
      confirmLabel: 'Log Out',
      isDestructive: true,
    );

    if (confirmed == true && context.mounted) {
      await context.read<AuthCubit>().signOut();
      if (context.mounted) {
        try {
          context.goNamed(RouteNames.login);
        } catch (_) {}
      }
    }
  }

  void _showHelpSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    AppBottomSheet.show(
      context: context,
      title: 'Help & FAQ',
      backgroundColor: isDark ? const Color(0xFF041E1C) : AppColors.ginFizz,
      child: Flexible(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              _HelpItem(
                question: 'How does splitting work?',
                answer: 'You can split bills equally, by exact amounts, or by percentage. Any house credits you have earned will automatically be applied to reduce your share!',
              ),
              SizedBox(height: 12),
              _HelpItem(
                question: 'What are House Credits?',
                answer: 'Complete chores on the roster to earn credits (10, 20, or 30 pts depending on difficulty). 100 credits = 1,000 RWF off your next bill.',
              ),
              SizedBox(height: 12),
              _HelpItem(
                question: 'What is Harmony Score?',
                answer: 'Harmony is a shared household score (0 to 100) reflecting chores done on time and debts settled promptly. It represents community health, never blame.',
              ),
              SizedBox(height: 12),
              _HelpItem(
                question: 'Need more assistance?',
                answer: 'Reach out to our team at support@changa.rw or speak with your household administrator.',
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _HelpItem extends StatelessWidget {
  final String question;
  final String answer;

  const _HelpItem({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF072B28) : AppColors.white;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: const Color(0xFF0F3E3A)) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.lightGreen : AppColors.sherwoodGreen,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            answer,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: isDark ? AppColors.pewter : AppColors.edward,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
