// Owner: A - Person A (Foundation, Authentication, Profile)
// Screen: Payment Methods Screen: select and manage settlement options

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/enums/settlement_method.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../cubit/preferences_cubit.dart';
import '../cubit/preferences_state.dart';

/// Screen allowing users to choose and manage their default settlement method.
class PaymentMethodsPage extends StatelessWidget {
  const PaymentMethodsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cubit = context.read<PreferencesCubit>();
    final user = context.watch<AuthCubit>().state.user;

    return BlocConsumer<PreferencesCubit, PreferencesState>(
      listenWhen: (prev, curr) =>
          curr.saveError != null && curr.saveError != prev.saveError,
      listener: (context, state) {
        AppSnackbar.error(context, state.saveError!);
        cubit.clearSaveError();
      },
      builder: (context, state) {
        final currentMethod = state.defaultSettlementMethod;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              color: isDark ? AppColors.ginFizz : AppColors.sherwoodGreen,
              onPressed: () => context.pop(),
            ),
            title: Text(
              'Payment Methods',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.ginFizz : AppColors.sherwoodGreen,
              ),
            ),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                // Info Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF072B28)
                        : AppColors.athsSpecial.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF0F3E3A)
                          : AppColors.athsSpecial,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 20,
                        color: isDark
                            ? AppColors.lightGreen
                            : AppColors.sherwoodGreen,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your default payment method is displayed to housemates whenever they settle debts with you.',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: isDark
                                ? AppColors.ginFizz
                                : AppColors.sherwoodGreen,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                const SectionHeader(title: 'Settlement Methods'),

                // MoMo Method Card
                _PaymentMethodCard(
                  key: const Key('payment-method-momo'),
                  title: 'Mobile Money (MoMo)',
                  subtitle: user?.phone.isNotEmpty == true
                      ? 'Registered number: ${user!.phone}'
                      : 'MTN MoMo or Airtel Money',
                  icon: Icons.phone_android_rounded,
                  isSelected: currentMethod == SettlementMethod.momo,
                  isDark: isDark,
                  onTap: () {
                    cubit.setDefaultSettlementMethod(SettlementMethod.momo);
                    AppSnackbar.success(
                      context,
                      'Default payment method set to Mobile Money.',
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Cash Method Card
                _PaymentMethodCard(
                  key: const Key('payment-method-cash'),
                  title: 'Cash',
                  subtitle: 'Physical in-person settlement between housemates',
                  icon: Icons.payments_outlined,
                  isSelected: currentMethod == SettlementMethod.cash,
                  isDark: isDark,
                  onTap: () {
                    cubit.setDefaultSettlementMethod(SettlementMethod.cash);
                    AppSnackbar.success(
                      context,
                      'Default payment method set to Cash.',
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Bank Transfer Method Card
                _PaymentMethodCard(
                  key: const Key('payment-method-bank'),
                  title: 'Bank Transfer',
                  subtitle: 'Bank of Kigali, Equity Bank, I&M Bank, etc.',
                  icon: Icons.account_balance_outlined,
                  isSelected: currentMethod == SettlementMethod.bank,
                  isDark: isDark,
                  onTap: () {
                    cubit.setDefaultSettlementMethod(SettlementMethod.bank);
                    AppSnackbar.success(
                      context,
                      'Default payment method set to Bank Transfer.',
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _PaymentMethodCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF072B28) : AppColors.white;
    final borderColor = isSelected
        ? AppColors.lightGreen
        : (isDark
              ? const Color(0xFF0F3E3A)
              : AppColors.edward.withValues(alpha: 0.15));

    final iconBg = isSelected
        ? (isDark
              ? const Color(0xFF0D3834)
              : AppColors.lightGreen.withValues(alpha: 0.15))
        : (isDark ? const Color(0xFF041E1C) : const Color(0xFFF7FAF8));

    final iconColor = isSelected
        ? (isDark ? AppColors.lightGreen : AppColors.sherwoodGreen)
        : (isDark ? AppColors.pewter : AppColors.edward);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: isSelected ? 1.8 : 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.ginFizz
                                : AppColors.sherwoodGreen,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.lightGreen.withValues(
                                alpha: 0.25,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'DEFAULT',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.sherwoodGreen,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: isDark ? AppColors.pewter : AppColors.edward,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppColors.lightGreen : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.lightGreen
                        : (isDark ? AppColors.pewter : AppColors.edward),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: AppColors.sherwoodGreen,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
