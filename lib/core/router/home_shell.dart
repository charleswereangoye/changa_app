import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/expenses/presentation/open_add_expense.dart';
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
