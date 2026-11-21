// Owner: A - Person A (Foundation, Authentication, Profile)
// Screen: Verify Email Screen: email verification status & resend matching Figma specifications

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../injection_container.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/verify_email_cubit.dart';

class VerifyEmailPage extends StatelessWidget {
  final VerifyEmailCubit? cubit;

  const VerifyEmailPage({super.key, this.cubit});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<VerifyEmailCubit>(
      create: (_) =>
          cubit ??
          (sl.isRegistered<VerifyEmailCubit>()
              ? sl<VerifyEmailCubit>()
              : VerifyEmailCubit()),
      child: const _VerifyEmailView(),
    );
  }
}

class _VerifyEmailView extends StatelessWidget {
  const _VerifyEmailView();

  @override
  Widget build(BuildContext context) {
    final authUser = context.watch<AuthCubit>().state.user;
    final userEmail = authUser?.email ?? 'your email address';

    return Scaffold(
      backgroundColor: AppColors.ginFizz,
      body: SafeArea(
        child: BlocConsumer<VerifyEmailCubit, VerifyEmailState>(
          listener: (context, state) {
            if (state.errorMessage != null) {
              AppSnackbar.error(context, state.errorMessage!);
            } else if (state.message != null) {
              AppSnackbar.success(context, state.message!);
            }

            if (state.isVerified) {
              AppSnackbar.success(context, 'Email verified successfully!');
              if (authUser != null) {
                context.read<AuthCubit>().updateUser(
                  authUser.copyWith(emailVerified: true),
                );
              }
              final hasHousehold =
                  authUser?.householdId != null &&
                  authUser!.householdId!.isNotEmpty;
              if (hasHousehold) {
                context.goNamed(RouteNames.dashboard);
              } else {
                context.goNamed(RouteNames.createHousehold);
              }
            }
          },
          builder: (context, state) {
            final cubit = context.read<VerifyEmailCubit>();

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Envelope Header Icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          color: AppColors.athsSpecial,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.mail_outline_rounded,
                          size: 40,
                          color: AppColors.sherwoodGreen,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Title
                      const Text(
                        'Verify your email',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.sherwoodGreen,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Explanatory body text
                      Text(
                        "We've sent a verification link to:\n$userEmail",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.sherwoodGreen,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Please tap the link in the email to confirm your account and access your household.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: AppColors.edward,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // "I've verified" primary button
                      PrimaryButton(
                        text: "I've Verified",
                        isLoading: state.isChecking,
                        onPressed: () {
                          cubit.checkVerificationStatus();
                        },
                      ),
                      const SizedBox(height: 14),

                      // Resend Email secondary button with cooldown
                      SecondaryButton(
                        label: state.resendCooldown > 0
                            ? 'Resend in ${state.resendCooldown}s'
                            : 'Resend Verification Email',
                        isLoading: state.isResending,
                        onPressed: state.canResend
                            ? () => cubit.resendVerificationEmail()
                            : null,
                      ),
                      const SizedBox(height: 24),

                      // Log out link
                      GestureDetector(
                        onTap: () {
                          context.read<AuthCubit>().signOut();
                          context.goNamed(RouteNames.login);
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Log Out / Use Different Account',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.sunglo,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
