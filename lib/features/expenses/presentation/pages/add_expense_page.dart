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
import 'package:changa_app/features/expenses/presentation/widgets/split_member_row.dart';
import 'package:changa_app/features/expenses/presentation/widgets/split_type_selector.dart';

class AddExpensePage extends StatelessWidget {
  const AddExpensePage({super.key});

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
      backgroundColor: AppColors.ginFizz,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
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
        final busy = state.status == AddExpenseStatus.submitting;

        return PopScope(
          canPop: !busy,
          child: SafeArea(
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
                  Row(
                    children: [
                      IconButton(
                        key: const Key('add-expense-close'),
                        onPressed: busy
                            ? null
                            : () => Navigator.of(context).maybePop(),
                        tooltip: 'Close',
                        icon: const Icon(
                          Icons.close,
                          color: AppColors.sherwoodGreen,
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          'Add Expense',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyLarge,
                        ),
                      ),
                      TextButton(
                        key: const Key('add-expense-save'),
                        onPressed: state.isValid && !busy ? cubit.submit : null,
                        child: Text(
                          'Save',
                          style: AppTextStyles.label.copyWith(
                            color: state.isValid && !busy
                                ? AppColors.leafGreen
                                : AppColors.edward,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'RWF',
                          style: AppTextStyles.heading2.copyWith(
                            color: AppColors.edward,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        IntrinsicWidth(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              minWidth: 80,
                              maxWidth: 220,
                            ),
                            child: TextField(
                              key: const Key('amount-field'),
                              enabled: !busy,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(9),
                              ],
                              style: AppTextStyles.heading1.copyWith(
                                fontSize: 40,
                              ),
                              onChanged: cubit.amountChanged,
                              decoration: const InputDecoration(
                                hintText: '0',
                                hintStyle: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 40,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.edward,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (state.amountError != null)
                    Center(child: _ProblemText(state.amountError!)),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    key: const Key('title-field'),
                    enabled: !busy,
                    textCapitalization: TextCapitalization.sentences,
                    inputFormatters: [LengthLimitingTextInputFormatter(60)],
                    style: AppTextStyles.bodyMedium,
                    onChanged: cubit.titleChanged,
                    decoration: _decoration(
                      hint: 'What was it for?',
                      errorText: state.titleError,
                      prefixIcon: const Icon(
                        Icons.description_outlined,
                        color: AppColors.edward,
                      ),
                    ),
                  ),
                  const _SectionLabel('Category'),
                  IgnorePointer(
                    ignoring: busy,
                    child: CategoryChips(
                      selected: state.category,
                      onSelected: cubit.categoryChanged,
                    ),
                  ),
                  const _SectionLabel('Paid by'),
                  IgnorePointer(
                    ignoring: busy,
                    child: ParticipantSelector(
                      keyPrefix: 'paid-by',
                      participants: state.participants,
                      selectedUids: [state.paidByUid],
                      onTap: cubit.paidByChanged,
                    ),
                  ),
                  const _SectionLabel('Split'),
                  IgnorePointer(
                    ignoring: busy,
                    child: SplitTypeSelector(
                      selected: state.splitType,
                      onChanged: cubit.splitTypeChanged,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  IgnorePointer(
                    ignoring: busy,
                    child: Column(
                      children: [
                        for (final person in state.participants)
                          SplitMemberRow(
                            participant: person,
                            selected: state.selectedUids.contains(person.uid),
                            splitType: state.splitType,
                            share: state.preview?.shares[person.uid],
                            initialText: state.weightTexts[person.uid] ?? '',
                            enabled: !busy,
                            onToggle: () => cubit.toggleParticipant(person.uid),
                            onChanged: (text) =>
                                cubit.weightChanged(person.uid, text),
                          ),
                      ],
                    ),
                  ),
                  if (state.participantsProblem != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    _ProblemText(state.participantsProblem!),
                  ],
                  if (state.splitType != SplitType.equal) ...[
                    const SizedBox(height: AppSpacing.sm),
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
                    text: 'Save Expense',
                    isLoading: busy,
                    onPressed: state.isValid ? cubit.submit : null,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static InputDecoration _decoration({
    String? hint,
    String? errorText,
    Widget? prefixIcon,
  }) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color),
    );

    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.bodySmall,
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: AppColors.white,
      errorText: errorText,
      errorStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.sunglo),
      enabledBorder: border(AppColors.athsSpecial),
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
      padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.sm),
      child: Text(
        text.toUpperCase(),
        style: AppTextStyles.bodySmall.copyWith(
          letterSpacing: 1.1,
          fontWeight: FontWeight.w600,
        ),
      ),
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
    final total = state.amount;
    final count = state.selectedUids.length;
    final people = count == 1 ? 'person' : 'people';
    final summary = total == null || state.amountProblem != null
        ? 'Enter the amount and choose who shares it to see the split.'
        : 'Total ${CurrencyFormatter.format(total)} split between '
              '$count $people';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.athsSpecial,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            summary,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium,
          ),
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
}
