import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../cubit/settle_cubit.dart';
import '../widgets/payment_method_selector.dart';

class SettleUpPage extends StatelessWidget {
  const SettleUpPage({super.key, this.memberNames = const {}, this.onDone});

  final Map<String, String> memberNames;
  final VoidCallback? onDone;

  String _nameOf(String? uid) {
    final name = memberNames[uid]?.trim();
    return name == null || name.isEmpty ? 'Former member' : name;
  }

  void _done(BuildContext context) {
    if (onDone != null) {
      onDone!();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.goNamed(RouteNames.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettleCubit, SettleState>(
      builder: (context, state) {
        return PopScope(
          canPop: !state.isSubmitting,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Settle Up'),
              leading: IconButton(
                tooltip: 'Close',
                onPressed: state.isSubmitting ? null : () => _done(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
            body: _buildBody(context, state),
            bottomNavigationBar: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: OutlinedButton(
                  onPressed: state.isSubmitting ? null : () => _done(context),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                  ),
                  child: const Text('Done'),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, SettleState state) {
    final cubit = context.read<SettleCubit>();
    final theme = Theme.of(context);

    if (state.action == SettlementAction.success) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            size: 72,
            color: AppColors.leafGreen,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'All settled with ${_nameOf(state.selectedOtherUid)}',
            key: const Key('settlement-success'),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Recorded via ${PaymentMethodSelector.labelFor(state.method)}.',
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    if (state.status == SettleStatus.initial ||
        state.status == SettleStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == SettleStatus.failure) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        children: [
          Text(
            state.failure?.message ?? 'Your balances could not be loaded.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: OutlinedButton(
              onPressed: state.isSubmitting ? null : cubit.retry,
              child: const Text('Try again'),
            ),
          ),
        ],
      );
    }

    if (state.allSettled && !state.isSubmitting) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            size: 64,
            color: AppColors.leafGreen,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'All settled',
            key: const Key('all-settled'),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'You have no outstanding net balances with your housemates.',
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    final entries =
        state.summary!.byMember.entries
            .where((entry) => entry.value != 0)
            .toList()
          ..sort((a, b) {
            final amountOrder = b.value.abs().compareTo(a.value.abs());
            return amountOrder != 0 ? amountOrder : a.key.compareTo(b.key);
          });

    final net = state.summary!.net;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          'Balances',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (state.isSubmitting) ...[
          const LinearProgressIndicator(),
          const SizedBox(height: AppSpacing.sm),
          const Text('Recording settlement…'),
          const SizedBox(height: AppSpacing.md),
        ],
        for (final entry in entries) ...[
          _memberCard(context, state, entry.key, entry.value),
          const SizedBox(height: AppSpacing.md),
        ],
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.sherwoodGreen,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your net balance',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.ginFizz,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${net > 0 ? '+' : ''}${CurrencyFormatter.format(net)}',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _memberCard(
    BuildContext context,
    SettleState state,
    String uid,
    int balance,
  ) {
    final cubit = context.read<SettleCubit>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final selected = state.selectedOtherUid == uid;
    final amount = CurrencyFormatter.format(balance.abs());

    return Material(
      key: ValueKey('settle-member-$uid'),
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: selected ? colors.primary : colors.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colors.primaryContainer,
                  foregroundColor: colors.onPrimaryContainer,
                  child: const Icon(Icons.person_outline_rounded),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    _nameOf(uid),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                TextButton(
                  key: ValueKey('select-settlement-$uid'),
                  onPressed: state.isSubmitting
                      ? null
                      : () => cubit.selectMember(uid),
                  style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
                  child: Text(selected ? 'Selected' : 'Settle'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              balance > 0 ? 'Owes you $amount' : 'You owe $amount',
              style: theme.textTheme.bodyMedium,
            ),
            if (selected) ...[
              const SizedBox(height: AppSpacing.lg),
              const Text('Payment method'),
              const SizedBox(height: AppSpacing.sm),
              PaymentMethodSelector(
                selectedMethod: state.method,
                enabled: !state.isSubmitting,
                onChanged: cubit.selectMethod,
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Choose how the payment was made, then record it here.',
              ),
              if (state.actionFailure != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  state.actionFailure!.message,
                  key: const Key('settlement-error'),
                  style: TextStyle(color: colors.error),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('confirm-settlement'),
                  onPressed: state.canConfirm ? cubit.confirm : null,
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                  child: Text(
                    state.isSubmitting ? 'Recording…' : 'Confirm settlement',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
