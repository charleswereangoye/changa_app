// Owner: C - Person C (Expenses, Dashboard, Documentation)
// Description: Expense details view, edit, and deletion bottom sheet

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

import 'package:changa_app/core/enums/settlement_method.dart';
import 'package:changa_app/core/theme/app_colors.dart';
import 'package:changa_app/core/theme/app_spacing.dart';
import 'package:changa_app/core/theme/app_text_styles.dart';
import 'package:changa_app/core/utils/currency_formatter.dart';
import 'package:changa_app/core/widgets/app_snackbar.dart';
import 'package:changa_app/core/widgets/member_avatar.dart';
import 'package:changa_app/core/widgets/money_text.dart';
import 'package:changa_app/core/widgets/primary_button.dart';
import 'package:changa_app/features/expenses/domain/entities/expense.dart';
import 'package:changa_app/features/expenses/domain/entities/split_type.dart';
import 'package:changa_app/features/expenses/domain/logic/expense_shares.dart';
import 'package:changa_app/features/expenses/domain/usecases/delete_expense.dart';
import 'package:changa_app/features/expenses/domain/usecases/update_expense_note.dart';
import 'package:changa_app/features/expenses/domain/usecases/watch_expense_debts.dart';
import 'package:changa_app/features/expenses/presentation/cubit/expense_detail_cubit.dart';
import 'package:changa_app/features/expenses/presentation/widgets/category_chips.dart';

/// The content of the Expense Details bottom sheet. It needs an
/// [ExpenseDetailCubit] above it; [ExpenseDetailSheet.show] creates one.
class ExpenseDetailSheet extends StatelessWidget {
  const ExpenseDetailSheet({
    super.key,
    required this.currentUid,
    this.names = const {},
  });

  final String currentUid;

  /// uid to display name. Unknown people show as "Housemate".
  final Map<String, String> names;

  static Future<void> show(
    BuildContext context, {
    required String householdId,
    required String currentUid,
    required Expense expense,
    Map<String, String> names = const {},
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppColors.white,
      builder: (_) => BlocProvider(
        create: (_) => ExpenseDetailCubit(
          updateExpenseNote: GetIt.instance<UpdateExpenseNote>(),
          deleteExpense: GetIt.instance<DeleteExpense>(),
          watchExpenseDebts: GetIt.instance<WatchExpenseDebts>(),
          householdId: householdId,
          expense: expense,
          currentUid: currentUid,
        ),
        child: ExpenseDetailSheet(currentUid: currentUid, names: names),
      ),
    );
  }

  String _nameOf(String uid) {
    if (uid == currentUid) return 'You';
    return names[uid] ?? 'Housemate';
  }

  void _onChange(BuildContext context, ExpenseDetailState state) {
    final failure = state.failure;
    if (failure != null) {
      AppSnackbar.error(context, failure.message);
    }
    if (state.status == ExpenseDetailStatus.saved) {
      AppSnackbar.success(context, 'Expense updated.');
    }
    if (state.status == ExpenseDetailStatus.deleted) {
      AppSnackbar.success(context, 'Expense deleted.');
      Navigator.of(context).pop();
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final cubit = context.read<ExpenseDetailCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this expense?'),
        content: const Text(
          'It will be removed for everyone, and any credits used on it will '
          'be refunded. This cannot be undone.',
        ),
        actions: [
          TextButton(
            key: const Key('detail-cancel-delete'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const Key('detail-confirm-delete'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.sunglo),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await cubit.delete();
    }
  }

  static String _splitLabel(SplitType type) => switch (type) {
    SplitType.equal => 'Split equally',
    SplitType.percent => 'Split by percent',
    SplitType.exact => 'Split by exact amounts',
  };

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ExpenseDetailCubit, ExpenseDetailState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          (current.failure != null && previous.failure != current.failure),
      listener: _onChange,
      builder: (context, state) {
        final cubit = context.read<ExpenseDetailCubit>();
        final expense = state.expense;

        return PopScope(
          canPop: !state.isBusy,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.xxl,
              0,
              AppSpacing.xxl,
              AppSpacing.xxl + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (state.isEditing) ...[
                    TextFormField(
                      key: const Key('detail-title-field'),
                      initialValue: state.titleDraft,
                      enabled: state.status == ExpenseDetailStatus.editing,
                      maxLength: 60,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: 'Title',
                        errorText: state.titleProblem,
                      ),
                      onChanged: cubit.titleChanged,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      key: const Key('detail-note-field'),
                      initialValue: state.noteDraft,
                      enabled: state.status == ExpenseDetailStatus.editing,
                      maxLength: 200,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Note (optional)',
                      ),
                      onChanged: cubit.noteChanged,
                    ),
                  ] else ...[
                    Text(
                      expense.title,
                      key: const Key('detail-title'),
                      style: AppTextStyles.heading2,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    MoneyText(
                      expense.totalAmount,
                      key: const Key('detail-amount'),
                      style: AppTextStyles.bodyLarge,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  _DetailRow(
                    label: 'Category',
                    value: CategoryChips.label(expense.category),
                  ),
                  _DetailRow(
                    label: 'Paid by',
                    value: _nameOf(expense.paidByUid),
                  ),
                  _DetailRow(
                    label: 'Split',
                    value: _splitLabel(expense.splitType),
                  ),
                  _DetailRow(
                    label: 'Added',
                    value: DateFormat('d MMM yyyy, HH:mm')
                        .format(expense.createdAt),
                  ),
                  if (!state.isEditing) ...[
                    const SizedBox(height: AppSpacing.md),
                    const Text('Who pays what', style: AppTextStyles.bodyLarge),
                    const SizedBox(height: AppSpacing.xs),
                    _Shares(state: state, nameOf: _nameOf),
                    const SizedBox(height: AppSpacing.md),
                    Text('Note', style: AppTextStyles.bodySmall),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      expense.note ?? 'No note yet.',
                      key: const Key('detail-note'),
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xxl),
                  if (!state.canManage)
                    Text(
                      'Only the person who paid can edit or delete this '
                      'expense.',
                      key: const Key('detail-readonly'),
                      style: AppTextStyles.bodySmall,
                    )
                  else if (state.isEditing) ...[
                    PrimaryButton(
                      key: const Key('detail-save'),
                      text: 'Save changes',
                      isLoading: state.status == ExpenseDetailStatus.saving,
                      onPressed: state.canSave ? cubit.save : null,
                    ),
                    Center(
                      child: TextButton(
                        key: const Key('detail-cancel'),
                        onPressed: state.isBusy ? null : cubit.cancelEdit,
                        child: const Text('Cancel'),
                      ),
                    ),
                  ] else ...[
                    PrimaryButton(
                      key: const Key('detail-edit'),
                      text: 'Edit title and note',
                      onPressed: state.isBusy ? null : cubit.startEdit,
                    ),
                    Center(
                      child: TextButton(
                        key: const Key('detail-delete'),
                        onPressed: state.canDelete
                            ? () => _confirmDelete(context)
                            : null,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.sunglo,
                        ),
                        child: Text(
                          state.status == ExpenseDetailStatus.deleting
                              ? 'Deleting...'
                              : 'Delete expense',
                        ),
                      ),
                    ),
                    if (state.deleteBlockedReason != null)
                      Text(
                        state.deleteBlockedReason!,
                        key: const Key('detail-delete-blocked'),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall,
                      )
                    else if (state.debtsStatus == ExpenseDebtsStatus.loading)
                      Text(
                        'Checking payments...',
                        key: const Key('detail-delete-checking'),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall,
                      ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTextStyles.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _Shares extends StatelessWidget {
  const _Shares({required this.state, required this.nameOf});

  final ExpenseDetailState state;
  final String Function(String uid) nameOf;

  @override
  Widget build(BuildContext context) {
    return switch (state.debtsStatus) {
      ExpenseDebtsStatus.loading => const Padding(
        key: Key('shares-loading'),
        padding: EdgeInsets.all(AppSpacing.md),
        child: Center(
          child: SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      ExpenseDebtsStatus.failed => const Text(
        "Couldn't load who has paid yet.",
        key: Key('shares-failed'),
        style: AppTextStyles.bodyMedium,
      ),
      ExpenseDebtsStatus.ready => Column(
        children: [
          for (final share in state.shares)
            _ShareRow(share: share, name: nameOf(share.uid)),
        ],
      ),
    };
  }
}

class _ShareRow extends StatelessWidget {
  const _ShareRow({required this.share, required this.name});

  final ExpenseShare share;
  final String name;

  static String _methodLabel(SettlementMethod? method) => switch (method) {
    SettlementMethod.momo => 'Mobile Money',
    SettlementMethod.cash => 'Cash',
    SettlementMethod.bank => 'Bank',
    SettlementMethod.credits => 'credits',
    null => '',
  };

  String get _statusText => switch (share.payment) {
    SharePayment.payer => 'Paid the bill',
    SharePayment.pending => 'Pending',
    SharePayment.paid =>
      share.method == null ? 'Paid' : 'Paid with ${_methodLabel(share.method)}',
    SharePayment.coveredByCredits => 'Covered by credits',
  };

  Color get _statusColor => switch (share.payment) {
    SharePayment.payer => AppColors.edward,
    SharePayment.pending => AppColors.sunglo,
    SharePayment.paid => AppColors.leafGreen,
    SharePayment.coveredByCredits => AppColors.leafGreen,
  };

  @override
  Widget build(BuildContext context) {
    final showCredits =
        share.payment == SharePayment.pending && share.creditsApplied > 0;

    return Padding(
      key: Key('share-${share.uid}'),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          MemberAvatar(uid: share.uid, name: name, radius: 16),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.bodyMedium),
                Text(
                  _statusText,
                  key: Key('share-status-${share.uid}'),
                  style: AppTextStyles.bodySmall.copyWith(color: _statusColor),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              MoneyText(share.amount, style: AppTextStyles.label),
              if (showCredits)
                Text(
                  '${CurrencyFormatter.format(share.amountDue)} after '
                  '${share.creditsApplied} pts',
                  style: AppTextStyles.bodySmall,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
