import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../expenses/domain/entities/expense.dart';
import '../cubit/debt_detail_cubit.dart';
import '../widgets/breakdown_tile.dart';

class DebtDetailPage extends StatelessWidget {
  const DebtDetailPage({
    super.key,
    this.housemateName = 'Former member',
    this.onSettle,
    this.onExpenseTap,
  });

  final String housemateName;
  final VoidCallback? onSettle;

  /// Connect this when the Expense Details sheet is available.
  final ValueChanged<Expense>? onExpenseTap;

  String get _name {
    final trimmed = housemateName.trim();
    return trimmed.isEmpty ? 'Former member' : trimmed;
  }

  void _openSettlement(BuildContext context, DebtDetailCubit cubit) {
    if (onSettle != null) {
      onSettle!();
      return;
    }

    context.pushNamed(
      RouteNames.settleUp,
      pathParameters: {'uid': cubit.otherUid},
      extra: {
        'householdId': cubit.householdId,
        'meUid': cubit.meUid,
        'housemateName': _name,
      },
    );
  }

  void _onChange(BuildContext context, DebtDetailState state) {
    if (state.nudgeStatus == NudgeStatus.sent) {
      AppSnackbar.success(context, 'Nudge sent to $_name');
    }

    if (state.nudgeStatus == NudgeStatus.failure) {
      final failure = state.nudgeFailure;

      final message = failure is NudgeCooldownFailure
          ? "You nudged $_name today. Let's give them a little time."
          : failure?.message ??
                'Your nudge could not be sent. Please try again.';

      AppSnackbar.error(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DebtDetailCubit, DebtDetailState>(
      listenWhen: (previous, current) =>
          previous.nudgeStatus != current.nudgeStatus,
      listener: _onChange,
      builder: (context, state) {
        final cubit = context.read<DebtDetailCubit>();
        final colors = Theme.of(context).colorScheme;
        final loaded = state.status == DebtDetailStatus.loaded;
        final showNudge = loaded && state.netBalance > 0;

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: colors.primaryContainer,
                  foregroundColor: colors.onPrimaryContainer,
                  child: const Icon(Icons.person_outline_rounded),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            actions: [
              if (showNudge)
                TextButton(
                  onPressed: state.canNudge ? cubit.sendNudge : null,
                  child: const Text('Send nudge'),
                ),
            ],
          ),
          body: _buildBody(context, state, cubit),
          bottomNavigationBar: loaded
              ? SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.sm,
                      children: [
                        if (state.debts.isNotEmpty)
                          OutlinedButton(
                            onPressed: state.canSettle
                                ? () => _openSettlement(context, cubit)
                                : null,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 48),
                            ),
                            child: const Text('Mark as settled'),
                          ),
                        if (showNudge)
                          FilledButton.icon(
                            onPressed: state.canNudge ? cubit.sendNudge : null,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 48),
                            ),
                            icon: state.nudgeStatus == NudgeStatus.sending
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.send_outlined),
                            label: Text(
                              state.nudgeStatus == NudgeStatus.sending
                                  ? 'Sending…'
                                  : 'Send Nudge',
                            ),
                          ),
                      ],
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    DebtDetailState state,
    DebtDetailCubit cubit,
  ) {
    final theme = Theme.of(context);

    if (state.status == DebtDetailStatus.initial ||
        state.status == DebtDetailStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == DebtDetailStatus.failure) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        children: [
          Text(
            state.failure?.message ??
                'Your shared balances could not be loaded.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: OutlinedButton(
              onPressed: cubit.retry,
              child: const Text('Try again'),
            ),
          ),
        ],
      );
    }

    final headline = state.netBalance > 0
        ? '$_name owes you'
        : state.netBalance < 0
        ? 'You owe $_name'
        : 'All settled up';

    final expenseCount = state.debts
        .map((debt) => debt.expenseId)
        .toSet()
        .length;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          decoration: BoxDecoration(
            color: AppColors.sherwoodGreen,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              Text(
                headline,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.ginFizz,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                CurrencyFormatter.format(state.netBalance.abs()),
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                expenseCount == 0
                    ? 'No pending shared expenses'
                    : 'Across $expenseCount shared '
                          '${expenseCount == 1 ? 'expense' : 'expenses'}',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.ginFizz,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text(
          'Itemized breakdown',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (state.debts.isEmpty)
          const Text('You have no pending shared balances with this housemate.')
        else
          for (final debt in state.debts) ...[
            BreakdownTile(
              debt: debt,
              meUid: cubit.meUid,
              expense: state.expensesById[debt.expenseId],
              onTap:
                  onExpenseTap == null ||
                      state.expensesById[debt.expenseId] == null
                  ? null
                  : () => onExpenseTap!(state.expensesById[debt.expenseId]!),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
      ],
    );
  }
}
