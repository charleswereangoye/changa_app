import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/dashboard/presentation/cubit/dashboard_cubit.dart';
import '../../features/expenses/presentation/open_add_expense.dart';
import '../../features/household/presentation/cubit/household_cubit.dart';
import '../widgets/app_bottom_navigation.dart';

/// Hosts the four main tabs and the shared Add Expense action.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTabTapped(int branchIndex) {
    navigationShell.goBranch(
      branchIndex,
      initialLocation: branchIndex == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.select((AuthCubit cubit) => cubit.state.user?.uid);
    final householdId = context.select(
      (HouseholdCubit cubit) => cubit.state.household?.id,
    );

    if (GetIt.instance.isRegistered<DashboardCubit>()) {
      return BlocProvider<DashboardCubit>(
        create: (_) =>
            GetIt.instance<DashboardCubit>()
              ..start(householdId: householdId, uid: uid),
        child: _HomeShellListener(
          navigationShell: navigationShell,
          onTabSelected: _onTabTapped,
        ),
      );
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: navigationShell.currentIndex,
        onTabSelected: _onTabTapped,
        onAddExpense: () => openAddExpense(context),
      ),
    );
  }
}

class _HomeShellListener extends StatelessWidget {
  const _HomeShellListener({
    required this.navigationShell,
    required this.onTabSelected,
  });

  final StatefulNavigationShell navigationShell;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<HouseholdCubit, HouseholdState>(
          listenWhen: (prev, curr) => prev.household?.id != curr.household?.id,
          listener: (context, state) {
            final uid = context.read<AuthCubit>().state.user?.uid;
            context.read<DashboardCubit>().start(
              householdId: state.household?.id,
              uid: uid,
            );
          },
        ),
        BlocListener<AuthCubit, AuthState>(
          listenWhen: (prev, curr) => prev.user?.uid != curr.user?.uid,
          listener: (context, state) {
            final householdId = context
                .read<HouseholdCubit>()
                .state
                .household
                ?.id;
            context.read<DashboardCubit>().start(
              householdId: householdId,
              uid: state.user?.uid,
            );
          },
        ),
      ],
      child: Scaffold(
        body: navigationShell,
        bottomNavigationBar: AppBottomNavigation(
          currentIndex: navigationShell.currentIndex,
          onTabSelected: onTabSelected,
          onAddExpense: () => openAddExpense(context),
        ),
      ),
    );
  }
}
