import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:changa_app/core/router/route_names.dart';
import 'package:changa_app/core/theme/app_colors.dart';
import 'package:changa_app/core/theme/app_spacing.dart';
import 'package:changa_app/core/theme/app_text_styles.dart';
import 'package:changa_app/core/utils/date_helpers.dart';
import 'package:changa_app/core/widgets/alert_modal.dart';
import 'package:changa_app/core/widgets/app_snackbar.dart';
import 'package:changa_app/core/widgets/primary_button.dart';
import 'package:changa_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:changa_app/features/chores/domain/entities/chore.dart';
import 'package:changa_app/features/chores/domain/usecases/create_chore.dart';
import 'package:changa_app/features/chores/domain/usecases/delete_chore.dart';
import 'package:changa_app/features/chores/domain/usecases/update_chore.dart';
import 'package:changa_app/features/chores/presentation/cubit/add_chore_cubit.dart';
import 'package:changa_app/features/chores/presentation/widgets/difficulty_selector.dart';
import 'package:changa_app/features/household/presentation/cubit/household_cubit.dart';

/// Add a chore, or change one. Pass [choreId] and [initial] to edit.
class AddEditChorePage extends StatelessWidget {
  const AddEditChorePage({super.key, this.choreId, this.initial});

  final String? choreId;
  final Chore? initial;

  bool get _isEdit => choreId != null;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, auth) {
        if (auth is AuthStateInitial || auth is AuthStateLoading) {
          return const _FormMessage.loading();
        }
        if (auth is! Authenticated) {
          return const _FormMessage(
            title: 'Please sign in',
            body: 'Sign in to manage your household’s chores.',
          );
        }

        return BlocBuilder<HouseholdCubit, HouseholdState>(
          builder: (context, household) {
            if (household is HouseholdStateInitial ||
                household is HouseholdStateLoading) {
              return const _FormMessage.loading();
            }
            final current = household.household;
            if (current == null) {
              return const _FormMessage(
                title: 'No household yet',
                body: 'Join or create a household to share chores.',
              );
            }
            if (_isEdit && initial == null) {
              return const _FormMessage(
                title: 'Chore not found',
                body: 'Open the chore from the roster to edit it.',
              );
            }

            final uid = auth.user.uid;
            final assignees = [
              for (final member in household.members)
                ChoreAssignee(
                  uid: member.uid,
                  name: member.uid == uid
                      ? 'You'
                      : household.displayNameFor(member.uid),
                ),
            ];

            return BlocProvider<AddChoreCubit>(
              key: ValueKey((current.id, uid, choreId)),
              create: (_) => AddChoreCubit(
                createChore: GetIt.I<CreateChore>(),
                updateChore: GetIt.I<UpdateChore>(),
                deleteChore: GetIt.I<DeleteChore>(),
                householdId: current.id,
                meUid: uid,
                assignees: assignees,
                editing: initial,
              ),
              child: const _ChoreForm(),
            );
          },
        );
      },
    );
  }
}

class _ChoreForm extends StatefulWidget {
  const _ChoreForm();

  @override
  State<_ChoreForm> createState() => _ChoreFormState();
}

class _ChoreFormState extends State<_ChoreForm> {
  late final TextEditingController _title;

  @override
  void initState() {
    super.initState();
    // Seeded once; after that the field owns what the user types.
    _title = TextEditingController(
      text: context.read<AddChoreCubit>().state.title,
    );
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context, AddChoreState state) async {
    final today = DateHelpers.startOfDay(DateTime.now());
    final first = state.dueDate.isBefore(today) ? state.dueDate : today;
    final picked = await showDatePicker(
      context: context,
      initialDate: state.dueDate,
      firstDate: first,
      lastDate: DateHelpers.addDays(today, 365),
    );
    if (picked != null && context.mounted) {
      context.read<AddChoreCubit>().dueDateChanged(picked);
    }
  }

  Future<void> _confirmDelete(BuildContext context, AddChoreState state) async {
    final cubit = context.read<AddChoreCubit>();
    final choice = await showDialog<_DeleteChoice>(
      context: context,
      builder: (dialog) => AlertModal(
        icon: Icons.delete_outline_rounded,
        title: 'Delete this chore?',
        body: state.isSeries
            ? 'This chore repeats every week. You can remove just this one '
                  'or the whole rotation.'
            : 'It will be removed from the roster for everyone.',
        primaryText: state.isSeries ? 'Just this one' : 'Delete chore',
        onPrimaryPressed: () => Navigator.of(dialog).pop(_DeleteChoice.one),
        secondaryText: state.isSeries ? 'The whole rotation' : null,
        onSecondaryPressed: state.isSeries
            ? () => Navigator.of(dialog).pop(_DeleteChoice.series)
            : null,
        dismissText: 'Keep it',
      ),
    );
    if (choice != null) {
      await cubit.delete(wholeSeries: choice == _DeleteChoice.series);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AddChoreCubit>();

    return BlocConsumer<AddChoreCubit, AddChoreState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == AddChoreStatus.success) {
          AppSnackbar.success(context, state.message ?? 'Saved.');
          if (context.canPop()) {
            context.pop();
          } else {
            context.goNamed(RouteNames.chores);
          }
        } else if (state.status == AddChoreStatus.failure) {
          AppSnackbar.error(
            context,
            state.message ?? 'Something went wrong. Please try again.',
          );
        }
      },
      builder: (context, state) {
        final busy = state.isBusy;
        final locked = state.isLocked;
        final theme = Theme.of(context);

        return PopScope(
          canPop: !busy,
          child: Scaffold(
            appBar: AppBar(
              title: Text(state.isEdit ? 'Edit chore' : 'Add chore'),
              actions: [
                if (state.isEdit)
                  IconButton(
                    tooltip: 'Delete chore',
                    onPressed: busy
                        ? null
                        : () => _confirmDelete(context, state),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
              ],
            ),
            body: SafeArea(
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
                    if (locked) ...[
                      const _Note(
                        'This chore is already done, so it can’t be changed.',
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    const _SectionLabel('Chore', first: true),
                    TextField(
                      key: const Key('chore-title-field'),
                      controller: _title,
                      enabled: !busy && !locked,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(
                          AddChoreCubit.maxTitleLength,
                        ),
                      ],
                      style: AppTextStyles.bodyMedium,
                      onChanged: cubit.titleChanged,
                      decoration: _decoration(
                        hint: 'Wash dishes, take out the bins',
                        errorText: state.titleError,
                      ),
                    ),
                    const _SectionLabel('Difficulty'),
                    DifficultySelector(
                      selected: state.difficulty,
                      enabled: !busy && !locked,
                      onChanged: cubit.difficultyChanged,
                    ),
                    const _SectionLabel('Assigned to'),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final person in state.assignees)
                          ChoiceChip(
                            key: Key('assignee-${person.uid}'),
                            label: Text(person.name),
                            selected: person.uid == state.assigneeUid,
                            onSelected: busy || locked
                                ? null
                                : (_) => cubit.assigneeChanged(person.uid),
                          ),
                      ],
                    ),
                    const _SectionLabel('Due'),
                    OutlinedButton.icon(
                      key: const Key('chore-due-button'),
                      onPressed: busy || locked
                          ? null
                          : () => _pickDate(context, state),
                      icon: const Icon(Icons.calendar_today_outlined, size: 18),
                      label: Text(_dayText(state.dueDate)),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        alignment: Alignment.centerLeft,
                        foregroundColor: AppColors.sherwoodGreen,
                        side: const BorderSide(color: AppColors.edward),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (state.isEdit)
                      state.isSeries
                          ? const _Note(
                              'Part of a weekly rotation. Changes here only '
                              'affect this week.',
                            )
                          : const SizedBox.shrink()
                    else
                      SwitchListTile(
                        key: const Key('chore-rotate-switch'),
                        contentPadding: EdgeInsets.zero,
                        value: state.rotate,
                        onChanged: busy ? null : cubit.rotateChanged,
                        title: Text(
                          'Rotate between everyone',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: const Text(
                          'Moves to the next housemate every week.',
                        ),
                      ),
                    const SizedBox(height: AppSpacing.xxl),
                    PrimaryButton(
                      text: state.isEdit ? 'Save changes' : 'Save chore',
                      isLoading: busy,
                      onPressed: state.canSubmit ? cubit.submit : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  static String _dayText(DateTime day) {
    final today = DateHelpers.startOfDay(DateTime.now());
    final prefix = DateHelpers.isSameDay(day, today)
        ? 'Today · '
        : DateHelpers.isSameDay(day, DateHelpers.addDays(today, 1))
        ? 'Tomorrow · '
        : '';
    return '$prefix${_days[day.weekday - 1]}, ${day.day} ${_months[day.month - 1]}';
  }

  static InputDecoration _decoration({String? hint, String? errorText}) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color),
    );

    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.bodySmall,
      errorText: errorText,
      errorStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.sunglo),
      enabledBorder: border(AppColors.edward),
      focusedBorder: border(AppColors.sherwoodGreen),
      errorBorder: border(AppColors.sunglo),
      focusedErrorBorder: border(AppColors.sunglo),
    );
  }
}

enum _DeleteChoice { one, series }

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {this.first = false});

  final String text;
  final bool first;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: first ? 0 : AppSpacing.lg,
        bottom: AppSpacing.sm,
      ),
      child: Text(text, style: AppTextStyles.label),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.athsSpecial,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: AppTextStyles.bodySmall),
    );
  }
}

class _FormMessage extends StatelessWidget {
  const _FormMessage({required this.title, required this.body})
    : loading = false;

  const _FormMessage.loading() : title = '', body = '', loading = true;

  final String title;
  final String body;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: loading
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.sm),
                    Text(body, textAlign: TextAlign.center),
                  ],
                ),
              ),
      ),
    );
  }
}
