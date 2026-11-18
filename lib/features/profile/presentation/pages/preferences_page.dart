// Owner: A - Person A (Foundation, Authentication, Profile)
// Screen: Preferences Screen: notification toggles and default options

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:changa_app/core/enums/settlement_method.dart';
import 'package:changa_app/core/enums/split_type.dart';
import 'package:changa_app/core/theme/app_colors.dart';
import 'package:changa_app/core/theme/app_spacing.dart';
import 'package:changa_app/core/widgets/app_snackbar.dart';
import 'package:changa_app/features/profile/presentation/cubit/preferences_cubit.dart';
import 'package:changa_app/features/profile/presentation/cubit/preferences_state.dart';

/// Notification toggles and defaults used when adding expenses and settling up.
/// Uses card-based layout matching Profile and clean light green active elements.
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF072B28) : AppColors.white;
    final cardBorder = isDark
        ? Border.all(color: const Color(0xFF0F3E3A))
        : null;

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
            centerTitle: true,
            leading: Navigator.of(context).canPop()
                ? IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                    ),
                    color: isDark ? AppColors.ginFizz : AppColors.sherwoodGreen,
                    onPressed: () => context.pop(),
                  )
                : null,
            title: Text(
              'Preferences',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.ginFizz : AppColors.sherwoodGreen,
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
                          AppSpacing.xs,
                          AppSpacing.lg,
                          AppSpacing.xxl,
                        ),
                        children: [
                          // Notifications Section
                          const _SectionLabel('Notifications', first: true),
                          Material(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16),
                            clipBehavior: Clip.antiAlias,
                            elevation: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: cardBorder,
                              ),
                              child: Column(
                                children: [
                                  SwitchListTile(
                                    key: const Key('notify-nudges-switch'),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 4,
                                    ),
                                    activeThumbColor: AppColors.white,
                                    activeTrackColor: AppColors.lightGreen,
                                    inactiveThumbColor: isDark
                                        ? AppColors.edward
                                        : AppColors.white,
                                    inactiveTrackColor: isDark
                                        ? AppColors.edward.withValues(
                                            alpha: 0.25,
                                          )
                                        : AppColors.edward.withValues(
                                            alpha: 0.3,
                                          ),
                                    title: Text(
                                      'Payment nudges',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? AppColors.ginFizz
                                            : AppColors.sherwoodGreen,
                                      ),
                                    ),
                                    subtitle: const Text(
                                      'When a housemate reminds you about a debt.',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 13,
                                        color: AppColors.edward,
                                      ),
                                    ),
                                    value: state.notifyNudges,
                                    onChanged: cubit.setNotifyNudges,
                                  ),
                                  Divider(
                                    height: 1,
                                    indent: 16,
                                    endIndent: 16,
                                    color: isDark
                                        ? const Color(0xFF0F3E3A)
                                        : const Color(0xFFF0F0EB),
                                  ),
                                  SwitchListTile(
                                    key: const Key('notify-chores-switch'),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 4,
                                    ),
                                    activeThumbColor: AppColors.white,
                                    activeTrackColor: AppColors.lightGreen,
                                    inactiveThumbColor: isDark
                                        ? AppColors.edward
                                        : AppColors.white,
                                    inactiveTrackColor: isDark
                                        ? AppColors.edward.withValues(
                                            alpha: 0.25,
                                          )
                                        : AppColors.edward.withValues(
                                            alpha: 0.3,
                                          ),
                                    title: Text(
                                      'Chore updates',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? AppColors.ginFizz
                                            : AppColors.sherwoodGreen,
                                      ),
                                    ),
                                    subtitle: const Text(
                                      'Swap requests and replies to your swaps.',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 13,
                                        color: AppColors.edward,
                                      ),
                                    ),
                                    value: state.notifyChores,
                                    onChanged: cubit.setNotifyChores,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Default payment method Section
                          const _SectionLabel('Default payment method'),
                          Material(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16),
                            elevation: 0,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: cardBorder,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Your default payment method shown when housemates settle with you.',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 13,
                                      color: isDark
                                          ? AppColors.ginFizz.withValues(
                                              alpha: 0.7,
                                            )
                                          : AppColors.edward,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Wrap(
                                    spacing: AppSpacing.sm,
                                    runSpacing: AppSpacing.sm,
                                    children: [
                                      for (final (method, label)
                                          in _settlementMethods)
                                        ChoiceChip(
                                          key: Key('settlement-${method.name}'),
                                          label: Text(
                                            label,
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              color:
                                                  state.defaultSettlementMethod ==
                                                      method
                                                  ? (isDark
                                                        ? AppColors.black
                                                        : AppColors
                                                              .sherwoodGreen)
                                                  : (isDark
                                                        ? AppColors.ginFizz
                                                        : AppColors
                                                              .sherwoodGreen),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          selected:
                                              state.defaultSettlementMethod ==
                                              method,
                                          selectedColor: AppColors.lightGreen,
                                          backgroundColor: isDark
                                              ? const Color(0xFF041E1C)
                                              : AppColors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          side: BorderSide(
                                            color:
                                                state.defaultSettlementMethod ==
                                                    method
                                                ? AppColors.lightGreen
                                                : (isDark
                                                      ? const Color(0xFF0F3E3A)
                                                      : AppColors.edward
                                                            .withValues(
                                                              alpha: 0.3,
                                                            )),
                                          ),
                                          showCheckmark: false,
                                          onSelected: (_) =>
                                              cubit.setDefaultSettlementMethod(
                                                method,
                                              ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Default split Section
                          const _SectionLabel('Default split'),
                          Material(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16),
                            elevation: 0,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: cardBorder,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Default calculation rule applied when you record group expenses.',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 13,
                                      color: isDark
                                          ? AppColors.ginFizz.withValues(
                                              alpha: 0.7,
                                            )
                                          : AppColors.edward,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Wrap(
                                    spacing: AppSpacing.sm,
                                    runSpacing: AppSpacing.sm,
                                    children: [
                                      for (final (type, label) in _splitTypes)
                                        ChoiceChip(
                                          key: Key('split-${type.name}'),
                                          label: Text(
                                            label,
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              color:
                                                  state.defaultSplitType == type
                                                  ? (isDark
                                                        ? AppColors.black
                                                        : AppColors
                                                              .sherwoodGreen)
                                                  : (isDark
                                                        ? AppColors.ginFizz
                                                        : AppColors
                                                              .sherwoodGreen),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          selected:
                                              state.defaultSplitType == type,
                                          selectedColor: AppColors.lightGreen,
                                          backgroundColor: isDark
                                              ? const Color(0xFF041E1C)
                                              : AppColors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          side: BorderSide(
                                            color:
                                                state.defaultSplitType == type
                                                ? AppColors.lightGreen
                                                : (isDark
                                                      ? const Color(0xFF0F3E3A)
                                                      : AppColors.edward
                                                            .withValues(
                                                              alpha: 0.3,
                                                            )),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(left: 4, top: first ? 0 : 8, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.ginFizz : AppColors.sherwoodGreen,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
