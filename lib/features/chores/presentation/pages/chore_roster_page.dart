import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:changa_app/core/router/route_names.dart';
import 'package:changa_app/core/theme/app_colors.dart';
import 'package:changa_app/core/theme/app_spacing.dart';
import 'package:changa_app/core/utils/date_helpers.dart';
import 'package:changa_app/core/widgets/app_snackbar.dart';
import 'package:changa_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:changa_app/features/chores/domain/usecases/complete_chore.dart';
import 'package:changa_app/features/chores/domain/usecases/watch_chores_for_day.dart';
import 'package:changa_app/features/chores/presentation/cubit/chores_cubit.dart';
import 'package:changa_app/features/chores/presentation/widgets/chore_card.dart';
import 'package:changa_app/features/chores/presentation/widgets/chore_day_strip.dart';
import 'package:changa_app/features/household/presentation/cubit/household_cubit.dart';

/// The Chores tab: this week's days, the chores for the open day, and a
/// quick way to tick your own off.
class ChoreRosterPage extends StatelessWidget {
  const ChoreRosterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, auth) {
        if (auth is AuthStateInitial || auth is AuthStateLoading) {
          return const _RosterMessage.loading();
        }
        if (auth is! Authenticated) {
          return const _RosterMessage(
            icon: Icons.lock_outline_rounded,
            title: 'Please sign in',
            body: 'Sign in to see your household’s chores.',
          );
        }

        return BlocBuilder<HouseholdCubit, HouseholdState>(
          builder: (context, household) {
            if (household is HouseholdStateInitial ||
                household is HouseholdStateLoading) {
              return const _RosterMessage.loading();
            }
            final current = household.household;
            if (current == null) {
              return const _RosterMessage(
                icon: Icons.home_outlined,
                title: 'No household yet',
                body: 'Join or create a household to share chores.',
              );
            }

            final uid = auth.user.uid;
            return BlocProvider<ChoresCubit>(
              key: ValueKey((current.id, uid)),
              create: (_) => ChoresCubit(
                watchChoresForDay: GetIt.I<WatchChoresForDay>(),
                completeChore: GetIt.I<CompleteChore>(),
                householdId: current.id,
                meUid: uid,
              )..load(),
              child: _RosterView(
                meUid: uid,
                credits: household.myCredits,
                nameOf: household.displayNameFor,
              ),
            );
          },
        );
      },
    );
  }
}

class _RosterView extends StatelessWidget {
  const _RosterView({
    required this.meUid,
    required this.credits,
    required this.nameOf,
  });

  final String meUid;
  final int credits;
  final String Function(String uid) nameOf;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: BlocListener<ChoresCubit, ChoresState>(
          listenWhen: (previous, current) =>
              current.notice != null && current.notice != previous.notice,
          listener: (context, state) {
            final notice = state.notice!;
            if (notice.isError) {
              AppSnackbar.error(context, notice.text);
            } else {
              AppSnackbar.success(context, notice.text);
            }
            context.read<ChoresCubit>().clearNotice();
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chore Roster',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'This week’s rotation',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.edward,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _CreditsPill(credits: credits),
                    const SizedBox(width: AppSpacing.sm),
                    IconButton.filled(
                      tooltip: 'Add a chore',
                      onPressed: () => context.pushNamed(RouteNames.addChore),
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: BlocBuilder<ChoresCubit, ChoresState>(
                  buildWhen: (previous, current) =>
                      previous.selectedDay != current.selectedDay,
                  builder: (context, state) => ChoreDayStrip(
                    days: state.weekDays,
                    selected: state.selectedDay,
                    today: state.today,
                    onSelected: context.read<ChoresCubit>().selectDay,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: _ChoreList(meUid: meUid, nameOf: nameOf),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreditsPill extends StatelessWidget {
  const _CreditsPill({required this.credits});

  final int credits;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'You have $credits credits',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.sunglo,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            'You: $credits pts',
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: AppColors.white, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

class _ChoreList extends StatelessWidget {
  const _ChoreList({required this.meUid, required this.nameOf});

  final String meUid;
  final String Function(String uid) nameOf;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<ChoresCubit, ChoresState>(
      builder: (context, state) {
        switch (state.status) {
          case ChoresStatus.loading:
            return const Center(child: CircularProgressIndicator());
          case ChoresStatus.failure:
            return _RosterMessage(
              icon: Icons.cloud_off_rounded,
              title: 'Couldn’t load chores',
              body: state.failure?.message ?? 'Please try again.',
              actionLabel: 'Try again',
              onAction: context.read<ChoresCubit>().retry,
            );
          case ChoresStatus.loaded:
            break;
        }

        final dayName = state.isSelectedDayToday
            ? 'Today'
            : DateHelpers.dayLabel(state.selectedDay);

        if (state.chores.isEmpty) {
          return _RosterMessage(
            icon: Icons.event_available_outlined,
            title: 'Nothing planned for $dayName',
            body: 'Tap + to add a chore.',
          );
        }

        final now = DateTime.now();
        final cubit = context.read<ChoresCubit>();

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.huge + AppSpacing.xxl,
          ),
          children: [
            Text(
              dayName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final chore in state.chores) ...[
              ChoreCard(
                chore: chore,
                isMine: chore.assignedToUid == meUid,
                assigneeName: chore.assignedToUid == meUid
                    ? 'You'
                    : nameOf(chore.assignedToUid).split(' ').first,
                isMissed: DateHelpers.isMissed(chore, now),
                isCompleting: state.completingIds.contains(chore.id),
                onComplete: () => cubit.completeChore(chore.id),
                onEdit: () => context.pushNamed(
                  RouteNames.editChore,
                  pathParameters: {'id': chore.id},
                  extra: chore,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ],
        );
      },
    );
  }
}

/// Friendly full-area message for loading, empty and error moments.
class _RosterMessage extends StatelessWidget {
  const _RosterMessage({
    required IconData this.icon,
    required String this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  }) : isLoading = false;

  const _RosterMessage.loading()
    : icon = null,
      title = null,
      body = null,
      actionLabel = null,
      onAction = null,
      isLoading = true;

  final IconData? icon;
  final String? title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.edward),
            const SizedBox(height: AppSpacing.md),
            Text(
              title!,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              body!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.edward,
              ),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
