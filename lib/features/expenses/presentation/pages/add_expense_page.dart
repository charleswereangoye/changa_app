// Owner: C - Person C (Expenses, Dashboard, Documentation)
// Screen: Add Expense Screen (bottom sheet): amount, category, split options

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'package:changa_app/core/enums/split_type.dart' as pref;
import 'package:changa_app/core/theme/app_colors.dart';
import 'package:changa_app/core/theme/app_spacing.dart';
import 'package:changa_app/core/theme/app_text_styles.dart';
import 'package:changa_app/core/utils/currency_formatter.dart';
import 'package:changa_app/core/widgets/app_snackbar.dart';
import 'package:changa_app/core/widgets/primary_button.dart';
import 'package:changa_app/features/expenses/domain/entities/split_type.dart';
import 'package:changa_app/features/expenses/domain/usecases/add_expense.dart';
import 'package:changa_app/features/expenses/presentation/cubit/add_expense_cubit.dart';
import 'package:changa_app/features/expenses/presentation/cubit/add_expense_state.dart';
import 'package:changa_app/features/expenses/presentation/widgets/category_chips.dart';
import 'package:changa_app/features/expenses/presentation/widgets/participant_selector.dart';
import 'package:changa_app/features/expenses/presentation/widgets/share_input_row.dart';
import 'package:changa_app/features/expenses/presentation/widgets/split_type_selector.dart';

/// The content of the Add Expense bottom sheet. It needs an
/// [AddExpenseCubit] above it; [AddExpensePage.show] creates one.
class AddExpensePage extends StatelessWidget {
  const AddExpensePage({super.key});

  /// Opens the form as a bottom sheet (dashboard quick action and the
  /// centre [+] button).
  static Future<void> show(
    BuildContext context, {
    required String householdId,
    required String currentUid,
    required List<ExpenseParticipant> participants,
    SplitType defaultSplitType = SplitType.equal,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppColors.white,
      builder: (_) => BlocProvider(
        create: (_) => AddExpenseCubit(
          addExpense: GetIt.instance<AddExpense>(),
          householdId: householdId,
          participants: participants,
          currentUid: currentUid,
          initialSplitType: defaultSplitType,
        ),
        child: const AddExpensePage(),
      ),
    );
  }

  /// The saved preference uses the app-wide enum; this form uses its own.
  static SplitType splitTypeFromPreference(pref.SplitType value) =>
      switch (value) {
        pref.SplitType.equal => SplitType.equal,
        pref.SplitType.byAmount => SplitType.exact,
        pref.SplitType.byPercentage => SplitType.percent,
      };

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AddExpenseCubit>();

    return BlocConsumer<AddExpenseCubit, AddExpenseState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == AddExpenseStatus.success) {
          AppSnackbar.success(context, 'Expense added.');
          Navigator.of(context).pop();
        } else if (state.status == AddExpenseStatus.failure) {
          AppSnackbar.error(
            context,
            state.failureMessage ??
                'Could not save the expense. Please try again.',
          );
        }
      },
      builder: (context, state) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Add expense', style: AppTextStyles.heading2),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  key: const Key('amount-field'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(9),
                  ],
                  style: AppTextStyles.heading2,
                  onChanged: cubit.amountChanged,
                  decoration: _decoration(
                    hint: '0',
                    prefixText: 'RWF ',
                    errorText: state.amountError,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  key: const Key('title-field'),
                  textCapitalization: TextCapitalization.sentences,
                  inputFormatters: [LengthLimitingTextInputFormatter(60)],
                  style: AppTextStyles.bodyMedium,
                  onChanged: cubit.titleChanged,
                  decoration: _decoration(
                    hint: 'Groceries, Simba Supermarket',
                    errorText: state.titleError,
                  ),
                ),
                const _SectionLabel('Category'),
                CategoryChips(
                  selected: state.category,
                  onSelected: cubit.categoryChanged,
                ),
                const _SectionLabel('Paid by'),
                ParticipantSelector(
                  keyPrefix: 'paid-by',
                  participants: state.participants,
                  selectedUids: [state.paidByUid],
                  onTap: cubit.paidByChanged,
                ),
                const _SectionLabel('Split'),
                SplitTypeSelector(
                  selected: state.splitType,
                  onChanged: cubit.splitTypeChanged,
                ),
                const _SectionLabel('Split with'),
                ParticipantSelector(
                  keyPrefix: 'split-with',
                  participants: state.participants,
                  selectedUids: state.selectedUids,
                  onTap: cubit.toggleParticipant,
                ),
                if (state.participantsProblem != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _ProblemText(state.participantsProblem!),
                ],
                if (state.splitType != SplitType.equal) ...[
                  const SizedBox(height: AppSpacing.lg),
                  for (final person in state.participants.where(
                    (p) => state.selectedUids.contains(p.uid),
                  ))
                    ShareInputRow(
                      participant: person,
                      splitType: state.splitType,
                      initialText: state.weightTexts[person.uid] ?? '',
                      onChanged: (text) =>
                          cubit.weightChanged(person.uid, text),
                    ),
                  _TotalLine(state: state),
                  if (state.visibleSplitProblem != null)
                    _ProblemText(state.visibleSplitProblem!),
                ],
                const SizedBox(height: AppSpacing.lg),
                _PreviewBox(state: state),
                if (state.status == AddExpenseStatus.failure &&
                    state.failureMessage != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _ProblemText(state.failureMessage!),
                ],
                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(
                  text: 'Save expense',
                  isLoading: state.status == AddExpenseStatus.submitting,
                  onPressed: state.isValid ? cubit.submit : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static InputDecoration _decoration({
    String? hint,
    String? errorText,
    String? prefixText,
  }) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color),
    );

    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.bodySmall,
      prefixText: prefixText,
      prefixStyle: AppTextStyles.heading2,
      errorText: errorText,
      errorStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.sunglo),
      enabledBorder: border(AppColors.edward),
      focusedBorder: border(AppColors.sherwoodGreen),
      errorBorder: border(AppColors.sunglo),
      focusedErrorBorder: border(AppColors.sunglo),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
      child: Text(text, style: AppTextStyles.label),
    );
  }
}

class _ProblemText extends StatelessWidget {
  const _ProblemText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.bodySmall.copyWith(color: AppColors.sunglo),
    );
  }
}

/// "Total: 100%" or "Remaining: RWF 0": green when right, coral when not.
class _TotalLine extends StatelessWidget {
  const _TotalLine({required this.state});

  final AddExpenseState state;

  @override
  Widget build(BuildContext context) {
    final isPercent = state.splitType == SplitType.percent;
    final isRight = isPercent
        ? state.weightsTotal == 100
        : state.remaining == 0;
    final text = isPercent
        ? 'Total: ${state.weightsTotal}%'
        : 'Remaining: ${CurrencyFormatter.format(state.remaining)}';

    return Text(
      text,
      style: AppTextStyles.label.copyWith(
        color: isRight ? AppColors.leafGreen : AppColors.sunglo,
      ),
    );
  }
}

class _PreviewBox extends StatelessWidget {
  const _PreviewBox({required this.state});

  final AddExpenseState state;

  @override
  Widget build(BuildContext context) {
    final preview = state.preview;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.athsSpecial,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_summary(preview), style: AppTextStyles.bodyMedium),
          if (preview != null && preview.creditsUsed > 0) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Credits applied: ${preview.creditsUsed} pts = '
              '${CurrencyFormatter.format(preview.creditsInRwf)}',
              style: AppTextStyles.label,
            ),
          ],
        ],
      ),
    );
  }

  String _summary(SplitPreview? preview) {
    if (preview == null) {
      return 'Enter the amount and choose who shares it to see the split.';
    }

    final count = preview.shares.length;
    final people = count == 1 ? 'person' : 'people';

    switch (state.splitType) {
      case SplitType.equal:
        final values = preview.shares.values;
        final low = values.reduce((a, b) => a < b ? a : b);
        final high = values.reduce((a, b) => a > b ? a : b);
        final each = low == high
            ? CurrencyFormatter.format(low)
            : '${CurrencyFormatter.format(low)} to ${CurrencyFormatter.format(high)}';
        return 'Split equally among $count $people, $each each';
      case SplitType.percent:
        return 'Split by percent among $count $people';
      case SplitType.exact:
        return 'Split by exact amounts among $count $people';
    }
  }
}
