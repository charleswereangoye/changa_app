// Owner: C - Person C (Expenses, Dashboard, Documentation)
// Description: Expense details view, edit, and deletion bottom sheet

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

import 'package:changa_app/core/theme/app_colors.dart';
import 'package:changa_app/core/theme/app_spacing.dart';
import 'package:changa_app/core/theme/app_text_styles.dart';
import 'package:changa_app/core/widgets/app_snackbar.dart';
import 'package:changa_app/core/widgets/money_text.dart';
import 'package:changa_app/core/widgets/primary_button.dart';
import 'package:changa_app/features/expenses/domain/entities/expense.dart';
import 'package:changa_app/features/expenses/domain/entities/split_type.dart';
import 'package:changa_app/features/expenses/domain/usecases/delete_expense.dart';
import 'package:changa_app/features/expenses/domain/usecases/update_expense_note.dart';
import 'package:changa_app/features/expenses/presentation/cubit/expense_detail_cubit.dart';
import 'package:changa_app/features/expenses/presentation/widgets/category_chips.dart';

/// The content of the Expense Details bottom sheet. It needs an
/// [ExpenseDetailCubit] above it; [ExpenseDetailSheet.show] creates one.
class ExpenseDetailSheet extends StatelessWidget {
  const ExpenseDetailSheet({super.key, this.payerName});

  /// Shown when someone else paid. The payer sees "You".
  final String? payerName;

  static Future<void> show(
    BuildContext context, {
    required String householdId,
    required String currentUid,
    required Expense expense,
    String? payerName,
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
          householdId: householdId,
          expense: expense,
          currentUid: currentUid,
        ),
        child: ExpenseDetailSheet(payerName: payerName),
      ),
    );
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
        final paidBy = state.canManage ? 'You' : (payerName ?? 'A housemate');

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
                  _DetailRow(label: 'Paid by', value: paidBy),
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
                        onPressed: state.isBusy
                            ? null
                            : () => _confirmDelete(context),
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
