import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';

/// Bottom navigation shell hosting Home, Chores, [+], Activity, and Profile
/// matching the exact Figma design system and elevated center action button.
class HomeShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const HomeShell({super.key, required this.navigationShell});

  void _onTabTapped(int branchIndex) {
    navigationShell.goBranch(
      branchIndex,
      initialLocation: branchIndex == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final currentIndex = navigationShell.currentIndex;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // White curved bottom bar with top shadow
          Container(
            height: 72 + bottomPadding,
            padding: EdgeInsets.only(bottom: bottomPadding),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // 1. Home
                _buildNavItem(
                  branchIndex: 0,
                  label: 'Home',
                  iconAsset: 'assets/icons/nav_home.svg',
                  isSelected: currentIndex == 0,
                ),
                // 2. Chores
                _buildNavItem(
                  branchIndex: 1,
                  label: 'Chores',
                  iconAsset: 'assets/icons/nav_chores.svg',
                  isSelected: currentIndex == 1,
                ),
                // Center spacer for the elevated Floating Action Button
                const SizedBox(width: 56),
                // 3. Activity
                _buildNavItem(
                  branchIndex: 2,
                  label: 'Activity',
                  iconAsset: 'assets/icons/nav_activity.svg',
                  isSelected: currentIndex == 2,
                ),
                // 4. Profile
                _buildNavItem(
                  branchIndex: 3,
                  label: 'Profile',
                  iconAsset: 'assets/icons/nav_profile.svg',
                  isSelected: currentIndex == 3,
                ),
              ],
            ),
          ),

          // Elevated Center Floating Action Button (+)
          Positioned(
            top: -20,
            child: GestureDetector(
              onTap: () => context.push('/expenses/add'),
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.lightGreen,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.lightGreen.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/icons/nav_plus.svg',
                    width: 24,
                    height: 24,
                    colorFilter: const ColorFilter.mode(
                      AppColors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int branchIndex,
    required String label,
    required String iconAsset,
    required bool isSelected,
  }) {
    final activeColor = AppColors.lightGreen;
    final inactiveColor = AppColors.edward;
    final currentColor = isSelected ? activeColor : inactiveColor;

    return Expanded(
      child: InkWell(
        onTap: () => _onTabTapped(branchIndex),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              iconAsset,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(currentColor, BlendMode.srcIn),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: currentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
