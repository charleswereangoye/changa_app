// Activity History Screen: month tabs, search, sticky date headers, activity list

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:changa_app/core/router/route_names.dart';
import 'package:changa_app/core/theme/app_colors.dart';
import 'package:changa_app/core/theme/app_spacing.dart';
import 'package:changa_app/features/activity/domain/entities/activity.dart';
import 'package:changa_app/features/activity/presentation/cubit/activity_cubit.dart';
import 'package:changa_app/features/activity/presentation/widgets/activity_tile.dart';
import 'package:changa_app/features/activity/presentation/widgets/date_group_header.dart';
import 'package:changa_app/features/household/presentation/cubit/household_cubit.dart';

class ActivityPage extends StatefulWidget {
  final ActivityCubit? cubit;
  final String? householdId;
  final String? currentUid;
  final Map<String, String>? memberNames;
  final Map<String, String>? refTitles;
  final DateTime? now;
  final ValueChanged<Activity>? onExpenseTap;
  final void Function(DateTime date, Activity activity)? onChoreTap;

  const ActivityPage({
    super.key,
    this.cubit,
    this.householdId,
    this.currentUid,
    this.memberNames,
    this.refTitles,
    this.now,
    this.onExpenseTap,
    this.onChoreTap,
  });

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  final _searchController = TextEditingController();
  late final ActivityCubit _cubit;
  late final bool _ownsCubit;
  String? _activeHouseholdId;

  @override
  void initState() {
    super.initState();
    if (widget.cubit != null) {
      _cubit = widget.cubit!;
      _ownsCubit = false;
    } else {
      ActivityCubit? fromContext;
      try {
        fromContext = context.read<ActivityCubit>();
      } catch (_) {
        fromContext = null;
      }

      if (fromContext != null) {
        _cubit = fromContext;
        _ownsCubit = false;
      } else if (GetIt.instance.isRegistered<ActivityCubit>()) {
        _cubit = GetIt.instance<ActivityCubit>();
        _ownsCubit = true;
      } else {
        _cubit = ActivityCubit();
        _ownsCubit = true;
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    if (_ownsCubit) {
      _cubit.close();
    }
    super.dispose();
  }

  HouseholdState? _watchHouseholdState(BuildContext context) {
    try {
      return context.watch<HouseholdCubit>().state;
    } catch (_) {
      if (GetIt.instance.isRegistered<HouseholdCubit>()) {
        return GetIt.instance<HouseholdCubit>().state;
      }
      return null;
    }
  }

  void _syncHouseholdSession(String? resolvedHouseholdId) {
    final cleanId = resolvedHouseholdId?.trim() ?? '';
    if (_activeHouseholdId == cleanId) return;
    _activeHouseholdId = cleanId;

    if (cleanId.isEmpty) {
      _cubit.clear();
    } else if (_cubit.state is ActivityStateInitial || _ownsCubit) {
      _cubit.start(householdId: cleanId);
    }
  }

  void _handleBack(BuildContext context) {
    try {
      if (context.canPop()) {
        context.pop();
      } else {
        context.goNamed(RouteNames.dashboard);
      }
    } catch (_) {
      // Safe fallback when tested outside GoRouter
    }
  }

  void _handleActivityTap(
    BuildContext context,
    Activity activity,
    String currentUid,
  ) {
    switch (activity.type) {
      case ActivityType.expenseAdded:
      case ActivityType.expenseDeleted:
      case ActivityType.debtSettled:
      case ActivityType.nudgeSent:
        if (widget.onExpenseTap != null) {
          widget.onExpenseTap!(activity);
          return;
        }
        final otherUid =
            (activity.targetUid != null &&
                activity.targetUid!.isNotEmpty &&
                activity.targetUid != currentUid)
            ? activity.targetUid!
            : (activity.actorUid != currentUid
                  ? activity.actorUid
                  : (activity.targetUid ?? ''));
        try {
          if (otherUid.isNotEmpty) {
            context.pushNamed(
              RouteNames.debtDetail,
              pathParameters: {'uid': otherUid},
              extra: activity.refId,
            );
          } else {
            context.goNamed(RouteNames.dashboard, extra: activity.refId);
          }
        } catch (_) {
          // Safe fallback when tested outside GoRouter
        }
        return;

      case ActivityType.choreCompleted:
      case ActivityType.swapRequested:
      case ActivityType.swapAccepted:
        if (widget.onChoreTap != null) {
          widget.onChoreTap!(activity.createdAt, activity);
          return;
        }
        try {
          context.goNamed(RouteNames.chores, extra: activity.createdAt);
        } catch (_) {
          // Safe fallback when tested outside GoRouter
        }
        return;

      case ActivityType.memberJoined:
      case ActivityType.memberRemoved:
        return;
    }
  }

  static List<_ActivityDateGroup> _groupActivitiesByDay(
    List<Activity> activities, {
    DateTime? now,
  }) {
    final groups = <_ActivityDateGroup>[];
    DateTime? currentDay;
    List<Activity> currentItems = <Activity>[];

    for (final activity in activities) {
      final local = activity.createdAt.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      if (currentDay == null || currentDay != day) {
        if (currentDay != null && currentItems.isNotEmpty) {
          groups.add(
            _ActivityDateGroup(
              day: currentDay,
              label: DateGroupHeader.formatLabel(currentDay, now: now),
              items: currentItems,
            ),
          );
        }
        currentDay = day;
        currentItems = <Activity>[activity];
      } else {
        currentItems.add(activity);
      }
    }

    if (currentDay != null && currentItems.isNotEmpty) {
      groups.add(
        _ActivityDateGroup(
          day: currentDay,
          label: DateGroupHeader.formatLabel(currentDay, now: now),
          items: currentItems,
        ),
      );
    }

    return groups;
  }

  static String _formatMonthTab(DateTime month, {DateTime? now}) {
    final referenceYear = (now ?? DateTime.now()).year;
    if (month.year == referenceYear) {
      return DateFormat('MMM').format(month);
    }
    return DateFormat('MMM yyyy').format(month);
  }

  @override
  Widget build(BuildContext context) {
    final householdState = _watchHouseholdState(context);
    final resolvedHouseholdId =
        widget.householdId ?? householdState?.household?.id;
    final resolvedUid =
        widget.currentUid ?? householdState?.currentMember?.uid ?? '';
    final resolvedNames =
        widget.memberNames ?? householdState?.memberNames ?? const {};
    final resolvedRefTitles = widget.refTitles ?? const {};

    _syncHouseholdSession(resolvedHouseholdId);

    return BlocProvider<ActivityCubit>.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: AppColors.ginFizz,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth < 360
                  ? AppSpacing.md
                  : AppSpacing.lg;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Header (Figma Back Circle + Title)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      AppSpacing.md,
                      horizontalPadding,
                      AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
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
                        const SizedBox(width: AppSpacing.md),
                        const Expanded(
                          child: Text(
                            'Activity History',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.sherwoodGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Search Field
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: AppSpacing.xs,
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _cubit.search,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: AppColors.sherwoodGreen,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search activity',
                        hintStyle: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: AppColors.edward,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: AppColors.edward,
                        ),
                        suffixIcon: ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _searchController,
                          builder: (context, value, _) {
                            if (value.text.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: AppColors.edward,
                              ),
                              tooltip: 'Clear search',
                              onPressed: () {
                                _searchController.clear();
                                _cubit.search('');
                              },
                            );
                          },
                        ),
                        filled: true,
                        fillColor: AppColors.white,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: const BorderSide(
                            color: AppColors.leafGreen,
                            width: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xs),

                  // Month Tabs + Content Body
                  Expanded(
                    child: BlocBuilder<ActivityCubit, ActivityState>(
                      builder: (context, state) {
                        if ((resolvedHouseholdId == null ||
                                resolvedHouseholdId.trim().isEmpty) &&
                            state is ActivityStateInitial) {
                          return const _EmptyActivityView(
                            title: 'No household connected',
                            subtitle: 'Join or create a household to view your shared activity history.',
                          );
                        }

                        final availableMonths = switch (state) {
                          ActivityStateLoaded(:final availableMonths) =>
                            availableMonths,
                          ActivityStateLoading(:final availableMonths) =>
                            availableMonths,
                          ActivityStateFailure(:final availableMonths) =>
                            availableMonths,
                          ActivityStateInitial() => const <DateTime>[],
                        };

                        final selectedMonth = switch (state) {
                          ActivityStateLoaded(:final selectedMonth) =>
                            selectedMonth,
                          ActivityStateLoading(:final selectedMonth) =>
                            selectedMonth,
                          ActivityStateFailure(:final selectedMonth) =>
                            selectedMonth,
                          ActivityStateInitial() => null,
                        };

                        final selectedIndex = selectedMonth == null
                            ? 0
                            : availableMonths
                                  .indexWhere((m) => m == selectedMonth)
                                  .clamp(
                                    0,
                                    availableMonths.isEmpty
                                        ? 0
                                        : availableMonths.length - 1,
                                  );

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (availableMonths.isNotEmpty) ...[
                              _MonthPillTabBar(
                                padding: EdgeInsets.symmetric(
                                  horizontal: horizontalPadding,
                                ),
                                tabs: [
                                  for (final month in availableMonths)
                                    _formatMonthTab(month, now: widget.now),
                                ],
                                selectedIndex: selectedIndex,
                                onTabSelected: (index) {
                                  if (index >= 0 &&
                                      index < availableMonths.length) {
                                    _cubit.selectMonth(availableMonths[index]);
                                  }
                                },
                              ),
                              const SizedBox(height: AppSpacing.sm),
                            ],
                            Expanded(
                              child: _buildStateContent(
                                context,
                                state: state,
                                horizontalPadding: horizontalPadding,
                                currentUid: resolvedUid,
                                memberNames: resolvedNames,
                                refTitles: resolvedRefTitles,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStateContent(
    BuildContext context, {
    required ActivityState state,
    required double horizontalPadding,
    required String currentUid,
    required Map<String, String> memberNames,
    required Map<String, String> refTitles,
  }) {
    if (state is ActivityStateInitial || state is ActivityStateLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is ActivityStateFailure) {
      return Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(horizontalPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                state.failure.message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: AppColors.sherwoodGreen,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(
                onPressed: _cubit.retry,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    if (state is ActivityStateLoaded) {
      final filtered = state.filterActivities(
        memberNames: memberNames,
        currentUid: currentUid,
        refTitles: refTitles,
      );

      if (state.activities.isEmpty) {
        final monthName = DateFormat('MMMM yyyy').format(state.selectedMonth);
        return _EmptyActivityView(
          title: 'No activity this month',
          subtitle:
              'There are no expenses, chores, or settlements recorded in $monthName.',
        );
      }

      if (filtered.isEmpty) {
        return _EmptyActivityView(
          title: 'No matching activity',
          subtitle: 'No activity lines matched "${state.searchQuery.trim()}".',
        );
      }

      final groups = _groupActivitiesByDay(filtered, now: widget.now);

      return CustomScrollView(
        slivers: [
          for (final group in groups)
            SliverMainAxisGroup(
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: StickyDateHeaderDelegate(label: group.label),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  sliver: SliverList.separated(
                    itemCount: group.items.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final activity = group.items[index];
                      return ActivityTile(
                        activity: activity,
                        memberNames: memberNames,
                        currentUid: currentUid,
                        refTitles: refTitles,
                        now: widget.now,
                        onTap: () =>
                            _handleActivityTap(context, activity, currentUid),
                      );
                    },
                  ),
                ),
              ],
            ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}

class _MonthPillTabBar extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final EdgeInsetsGeometry padding;

  const _MonthPillTabBar({
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: tabs.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final isSelected = index == selectedIndex;
          final label = tabs[index];

          return Semantics(
            button: true,
            selected: isSelected,
            label: label,
            child: Material(
              color: isSelected ? AppColors.sherwoodGreen : AppColors.white,
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => onTabSelected(index),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.sherwoodGreen
                          : AppColors.sherwoodGreen.withValues(alpha: 0.12),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected
                          ? AppColors.white
                          : AppColors.sherwoodGreen,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ActivityDateGroup {
  final DateTime day;
  final String label;
  final List<Activity> items;

  const _ActivityDateGroup({
    required this.day,
    required this.label,
    required this.items,
  });
}

class _EmptyActivityView extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyActivityView({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.opal.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history_rounded,
                size: 28,
                color: AppColors.sherwoodGreen,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.sherwoodGreen,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: AppColors.edward,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

