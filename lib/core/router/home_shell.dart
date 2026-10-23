import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';

/// Bottom navigation shell hosting Home, Chores, [+], Activity, and Profile.
class HomeShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const HomeShell({super.key, required this.navigationShell});

  void _onDestinationSelected(BuildContext context, int index) {
    if (index == 2) {
      // Centre button opens Add Expense
      context.push('/expenses/add');
      return;
    }
    final branchIndex = index > 2 ? index - 1 : index;
    navigationShell.goBranch(
      branchIndex,
      initialLocation: branchIndex == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = navigationShell.currentIndex;
    final navBarIndex = currentIndex >= 2 ? currentIndex + 1 : currentIndex;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navBarIndex,
        onDestinationSelected: (index) =>
            _onDestinationSelected(context, index),
        backgroundColor: AppColors.white,
        indicatorColor: AppColors.athsSpecial,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(
              Icons.home_rounded,
              color: AppColors.sherwoodGreen,
            ),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(
              Icons.checklist_rounded,
              color: AppColors.sherwoodGreen,
            ),
            label: 'Chores',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline, size: 28),
            selectedIcon: Icon(
              Icons.add_circle,
              size: 28,
              color: AppColors.sherwoodGreen,
            ),
            label: 'Add',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(
              Icons.history_rounded,
              color: AppColors.sherwoodGreen,
            ),
            label: 'Activity',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(
              Icons.person_rounded,
              color: AppColors.sherwoodGreen,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
