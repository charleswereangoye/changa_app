import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';

/// Navigation that preserves scaled labels and grows to fit their height.
class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onAddExpense,
  });

  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onAddExpense;

  static const _tabs = [
    ('Home', 'assets/icons/nav_home.svg'),
    ('Chores', 'assets/icons/nav_chores.svg'),
    ('Activity', 'assets/icons/nav_activity.svg'),
    ('Profile', 'assets/icons/nav_profile.svg'),
  ];

  @override
  Widget build(BuildContext context) {
    final labelStyle = DefaultTextStyle.of(context).style.merge(
      const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        var requiredWidth = 48.0;

        for (final (label, _) in _tabs) {
          final painter = TextPainter(
            text: TextSpan(text: label, style: labelStyle),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
            locale: Localizations.maybeLocaleOf(context),
          )..layout();

          final width = painter.width.ceilToDouble() + 24;
          if (width > requiredWidth) {
            requiredWidth = width;
          }

          painter.dispose();
        }

        final availableWidth = (constraints.maxWidth - 56) / 4;
        final scrollTabs = availableWidth < requiredWidth;
        final itemWidth = scrollTabs ? requiredWidth : availableWidth;

        final bar = Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 72),
              child: SingleChildScrollView(
                key: const Key('bottom-navigation-scroll'),
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var index = 0; index < _tabs.length; index++) ...[
                      if (index == 2)
                        scrollTabs
                            ? _addButton()
                            : const SizedBox(width: 56, height: 56),
                      SizedBox(
                        width: itemWidth,
                        child: _tab(index, labelStyle),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );

        if (scrollTabs) {
          return bar;
        }

        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            bar,
            Positioned(top: -20, child: _addButton()),
          ],
        );
      },
    );
  }

  Widget _tab(int index, TextStyle labelStyle) {
    final (label, asset) = _tabs[index];
    final selected = currentIndex == index;
    final color = selected ? AppColors.lightGreen : AppColors.edward;

    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('bottom-tab-$index'),
          onTap: () => onTabSelected(index),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  asset,
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  softWrap: false,
                  style: labelStyle.copyWith(
                    color: AppColors.sherwoodGreen,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _addButton() {
    return SizedBox(
      width: 56,
      height: 56,
      child: IconButton.filled(
        key: const Key('bottom-add-expense'),
        tooltip: 'Add expense',
        onPressed: onAddExpense,
        style: IconButton.styleFrom(
          backgroundColor: AppColors.lightGreen,
          foregroundColor: AppColors.white,
        ),
        icon: SvgPicture.asset(
          'assets/icons/nav_plus.svg',
          width: 24,
          height: 24,
          colorFilter: const ColorFilter.mode(AppColors.white, BlendMode.srcIn),
        ),
      ),
    );
  }
}
