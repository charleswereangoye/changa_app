import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:changa_app/core/theme/app_spacing.dart';
import 'package:changa_app/core/theme/app_text_styles.dart';
import 'package:changa_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:changa_app/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:changa_app/features/dashboard/presentation/widgets/balance_summary_card.dart';
import 'package:changa_app/features/dashboard/presentation/widgets/dashboard_empty_state.dart';
import 'package:changa_app/features/dashboard/presentation/widgets/harmony_card.dart';
import 'package:changa_app/features/dashboard/presentation/widgets/harmony_explainer_sheet.dart';
import 'package:changa_app/features/dashboard/presentation/widgets/quick_actions.dart';
import 'package:changa_app/features/dashboard/presentation/widgets/recent_activity_list.dart';
import 'package:changa_app/features/debts/domain/entities/balance_summary.dart';
import 'package:changa_app/features/expenses/presentation/open_add_expense.dart';
import 'package:changa_app/features/household/presentation/cubit/household_cubit.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.select((AuthCubit cubit) => cubit.state.user?.uid);

    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<HouseholdCubit, HouseholdState>(
          builder: (context, state) {
            if (state is HouseholdStateEmpty) {
              return Center(
                child: SingleChildScrollView(
                  child: DashboardEmptyState(
                    title: 'Welcome to Changa',
                    message: 'Create a household for your home, or join one with a PIN from a housemate.',
                    primaryLabel: 'Create a household',
                    onPrimary: () => context.push('/household/create'),
                    secondaryLabel: 'Join with a PIN',
                    onSecondary: () => context.push('/household/join'),
                  ),
                ),
              );
            }

            if (state is HouseholdStateError) {
              return const Center(
                child: DashboardEmptyState(
                  title: 'We could not load your home',
                  message: 'Check your connection and reopen the app.',
                ),
              );
            }

            final household = state.household;
            if (household == null || uid == null) {
              return const Center(child: CircularProgressIndicator());
            }

            return _HouseholdDashboard(
              key: ValueKey('${household.id}-$uid'),
              householdId: household.id,
              householdName: household.name,
              uid: uid,
              names: state.memberNames,
            );
          },
        ),
      ),
    );
  }
}

class _HouseholdDashboard extends StatelessWidget {
  const _HouseholdDashboard({
    super.key,
    required this.householdId,
    required this.householdName,
    required this.uid,
    required this.names,
  });

  final String householdId;
  final String householdName;
  final String uid;
  final Map<String, String> names;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DashboardCubit>(
      create: (_) =>
          GetIt.instance<DashboardCubit>()
            ..start(householdId: householdId, uid: uid),
      child: _DashboardBody(
        householdName: householdName,
        uid: uid,
        names: names,
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.householdName,
    required this.uid,
    required this.names,
  });

  final String householdName;
  final String uid;
  final Map<String, String> names;

  void _settleUp(BuildContext context, BalanceSummary? summary) {
    final owed =
        (summary?.byMember.entries ?? const <MapEntry<String, int>>[])
            .where((entry) => entry.value < 0)
            .toList()
          ..sort((a, b) => a.value.compareTo(b.value));

    if (owed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You do not owe anyone right now.')),
      );
      return;
    }

    context.push('/debts/${owed.first.key}');
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        final cubit = context.read<DashboardCubit>();

        final header = Text(householdName, style: AppTextStyles.heading2);

        if (state.isEmptyHousehold) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              header,
              DashboardEmptyState(
                title: 'All quiet so far',
                message:
                    'Add your first expense to start tracking who owes what.',
                primaryLabel: 'Add expense',
                onPrimary: () => openAddExpense(context),
                secondaryLabel: 'Add a chore',
                onSecondary: () => context.push('/chores/add'),
              ),
            ],
          );
        }

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            header,
            const SizedBox(height: AppSpacing.lg),
            HarmonyCard(
              status: state.harmonyStatus,
              score: state.harmony,
              onInfo: () => HarmonyExplainerSheet.show(context),
            ),
            const SizedBox(height: AppSpacing.lg),
            BalanceSummaryCard(
              status: state.balanceStatus,
              summary: state.balance,
              names: names,
              onRetry: cubit.retry,
              onMemberTap: (memberUid) => context.push('/debts/$memberUid'),
            ),
            const SizedBox(height: AppSpacing.lg),
            QuickActions(
              onAddExpense: () => openAddExpense(context),
              onSettleUp: () => _settleUp(context, state.balance),
              onAddChore: () => context.push('/chores/add'),
            ),
            const SizedBox(height: AppSpacing.lg),
            RecentActivityList(
              status: state.activityStatus,
              items: state.recentActivity,
              names: names,
              currentUid: uid,
              onSeeAll: () => context.go('/home/activity'),
            ),
          ],
        );
      },
    );
  }
}
