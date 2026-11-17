import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:changa_app/core/enums/settlement_method.dart';
import 'package:changa_app/core/enums/split_type.dart';
import 'package:changa_app/core/theme/app_colors.dart';
import 'package:changa_app/core/theme/app_spacing.dart';
import 'package:changa_app/core/widgets/app_snackbar.dart';
import 'package:changa_app/features/profile/presentation/cubit/preferences_cubit.dart';
import 'package:changa_app/features/profile/presentation/cubit/preferences_state.dart';

/// Theme, notification toggles and the defaults used when adding expenses
/// and settling up. Needs a [PreferencesCubit] above it.
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
          appBar: AppBar(title: const Text('Preferences')),
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
                          const _SectionLabel('Appearance', first: true),
                          SegmentedButton<ThemeMode>(
                            key: const Key('theme-selector'),
                            showSelectedIcon: false,
                            segments: const [
                              ButtonSegment(
                                value: ThemeMode.system,
                                label: Text('System'),
                              ),
                              ButtonSegment(
                                value: ThemeMode.light,
                                label: Text('Light'),
                              ),
                              ButtonSegment(
                                value: ThemeMode.dark,
                                label: Text('Dark'),
                              ),
                            ],
                            selected: {state.themeMode},
                            onSelectionChanged: (selection) =>
                                cubit.setThemeMode(selection.first),
                          ),
                          const _SectionLabel('Notifications'),
                          SwitchListTile(
                            key: const Key('notify-nudges-switch'),
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Payment nudges'),
                            subtitle: const Text(
                              'When a housemate reminds you about a debt.',
                            ),
                            value: state.notifyNudges,
                            onChanged: cubit.setNotifyNudges,
                          ),
                          SwitchListTile(
                            key: const Key('notify-chores-switch'),
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Chore updates'),
                            subtitle: const Text(
                              'Swap requests and replies to your swaps.',
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
                                  label: Text(label),
                                  selected:
                                      state.defaultSettlementMethod == method,
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
                                  label: Text(label),
                                  selected: state.defaultSplitType == type,
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
          fontWeight: FontWeight.w700,
          color: AppColors.sherwoodGreen,
        ),
      ),
    );
  }
}
