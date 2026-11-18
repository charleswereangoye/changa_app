import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:changa_app/core/enums/settlement_method.dart';
import 'package:changa_app/core/enums/split_type.dart';
import 'package:changa_app/core/theme/app_colors.dart';
import 'package:changa_app/core/theme/app_spacing.dart';
import 'package:changa_app/core/widgets/app_snackbar.dart';
import 'package:changa_app/features/profile/presentation/cubit/preferences_cubit.dart';
import 'package:changa_app/features/profile/presentation/cubit/preferences_state.dart';

/// Notification toggles and defaults used when adding expenses and settling up.
/// Uses light green for nudges and active switches.
class PreferencesPage extends StatelessWidget {
  const PreferencesPage({super.key});

  static const _settlementMethods = [
    (SettlementMethod.momo, 'Mobile Money'),
    (SettlementMethod.cash, 'Cash'),
    (SettlementMethod.bank, 'Bank'),
  ];

  static const _splitTypes = [
    (SplitType.equal, 'Equal'),
    (SplitType.byAmount, 'By amount'),
    (SplitType.byPercentage, 'By percentage'),
  ];

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PreferencesCubit>();

    return BlocConsumer<PreferencesCubit, PreferencesState>(
      listenWhen: (previous, current) =>
          current.saveError != null && current.saveError != previous.saveError,
      listener: (context, state) {
        AppSnackbar.error(context, state.saveError!);
        cubit.clearSaveError();
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            title: const Text(
              'Preferences',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                color: AppColors.sherwoodGreen,
              ),
            ),
          ),
          body: SafeArea(
            child: !state.isLoaded
                ? const Center(child: CircularProgressIndicator())
                : Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.sm,
                          AppSpacing.lg,
                          AppSpacing.xxl,
                        ),
                        children: [
                          const _SectionLabel('Notifications', first: true),
                          SwitchListTile(
                            key: const Key('notify-nudges-switch'),
                            contentPadding: EdgeInsets.zero,
                            activeThumbColor: AppColors.white,
                            activeTrackColor: AppColors.lightGreen,
                            inactiveThumbColor: AppColors.edward,
                            inactiveTrackColor: AppColors.edward.withValues(
                              alpha: 0.25,
                            ),
                            title: const Text(
                              'Payment nudges',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                color: AppColors.sherwoodGreen,
                              ),
                            ),
                            subtitle: const Text(
                              'When a housemate reminds you about a debt.',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: AppColors.edward,
                              ),
                            ),
                            value: state.notifyNudges,
                            onChanged: cubit.setNotifyNudges,
                          ),
                          SwitchListTile(
                            key: const Key('notify-chores-switch'),
                            contentPadding: EdgeInsets.zero,
                            activeThumbColor: AppColors.white,
                            activeTrackColor: AppColors.lightGreen,
                            inactiveThumbColor: AppColors.edward,
                            inactiveTrackColor: AppColors.edward.withValues(
                              alpha: 0.25,
                            ),
                            title: const Text(
                              'Chore updates',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                color: AppColors.sherwoodGreen,
                              ),
                            ),
                            subtitle: const Text(
                              'Swap requests and replies to your swaps.',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: AppColors.edward,
                              ),
                            ),
                            value: state.notifyChores,
                            onChanged: cubit.setNotifyChores,
                          ),
                          const _SectionLabel('Default payment method'),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              for (final (method, label) in _settlementMethods)
                                ChoiceChip(
                                  key: Key('settlement-${method.name}'),
                                  label: Text(
                                    label,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      color: AppColors.sherwoodGreen,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  selected:
                                      state.defaultSettlementMethod == method,
                                  selectedColor: AppColors.lightGreen,
                                  backgroundColor: AppColors.white,
                                  side: BorderSide(
                                    color:
                                        state.defaultSettlementMethod == method
                                        ? AppColors.lightGreen
                                        : AppColors.edward.withValues(
                                            alpha: 0.3,
                                          ),
                                  ),
                                  showCheckmark: false,
                                  onSelected: (_) =>
                                      cubit.setDefaultSettlementMethod(method),
                                ),
                            ],
                          ),
                          const _SectionLabel('Default split'),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              for (final (type, label) in _splitTypes)
                                ChoiceChip(
                                  key: Key('split-${type.name}'),
                                  label: Text(
                                    label,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      color: AppColors.sherwoodGreen,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  selected: state.defaultSplitType == type,
                                  selectedColor: AppColors.lightGreen,
                                  backgroundColor: AppColors.white,
                                  side: BorderSide(
                                    color: state.defaultSplitType == type
                                        ? AppColors.lightGreen
                                        : AppColors.edward.withValues(
                                            alpha: 0.3,
                                          ),
                                  ),
                                  showCheckmark: false,
                                  onSelected: (_) =>
                                      cubit.setDefaultSplitType(type),
                                ),
                            ],
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
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {this.first = false});

  final String text;
  final bool first;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: first ? 0 : AppSpacing.xl,
        bottom: AppSpacing.sm,
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
          color: AppColors.sherwoodGreen,
        ),
      ),
    );
  }
}
