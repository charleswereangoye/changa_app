// Owner: A - Person A (Foundation, Authentication, Profile)
// Screen: Forgot Password Screen: password reset request matching Figma specifications

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../injection_container.dart';
import '../cubit/forgot_password_cubit.dart';
import '../widgets/auth_back_button.dart';

class ForgotPasswordPage extends StatefulWidget {
  final ForgotPasswordCubit? cubit;

  const ForgotPasswordPage({super.key, this.cubit});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<ForgotPasswordCubit>().submitEmail(_emailController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ForgotPasswordCubit>(
      create: (_) =>
          widget.cubit ??
          (sl.isRegistered<ForgotPasswordCubit>()
              ? sl<ForgotPasswordCubit>()
              : ForgotPasswordCubit()),
      child: Scaffold(
        backgroundColor: AppColors.ginFizz,
        body: SafeArea(
          child: BlocConsumer<ForgotPasswordCubit, ForgotPasswordState>(
            listener: (context, state) {
              if (state is ForgotPasswordFailure) {
                AppSnackbar.error(context, state.errorMessage);
              } else if (state is ForgotPasswordSuccess) {
                AppSnackbar.success(context, state.message);
              }
            },
            builder: (context, state) {
              final isSuccess = state is ForgotPasswordSuccess;
              final isLoading = state is ForgotPasswordLoading;

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AuthBackButton(fallbackLocation: '/login'),
                        const SizedBox(height: 16),

                        if (!isSuccess) ...[
                          const Text(
                            'Reset Password',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.sherwoodGreen,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            "Enter the email associated with your account and we'll send you a link to reset your password.",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: AppColors.edward,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Form(
                            key: _formKey,
                            child: AppTextField(
                              label: 'Email Address',
                              hintText: 'you@school.edu',
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              prefixIcon: const Icon(
                                Icons.mail_outline_rounded,
                                color: AppColors.edward,
                                size: 20,
                              ),
                              validator: Validators.email,
                            ),
                          ),
                          const SizedBox(height: 24),
                          PrimaryButton(
                            text: 'Send Reset Link',
                            isLoading: isLoading,
                            onPressed: () => _submit(context),
                          ),
                        ] else ...[
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: const BoxDecoration(
                                    color: AppColors.athsSpecial,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.mark_email_read_outlined,
                                    size: 38,
                                    color: AppColors.sherwoodGreen,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Check your inbox',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.sherwoodGreen,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "We've sent password reset instructions to ${_emailController.text.trim()}. Please check your email to continue.",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.edward,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 32),
                                PrimaryButton(
                                  text: 'Back to Login',
                                  onPressed: () {
                                    if (context.canPop()) {
                                      context.pop();
                                    } else {
                                      context.go('/login');
                                    }
                                  },
                                ),
                                const SizedBox(height: 12),
                                SecondaryButton(
                                  label: 'Resend Email',
                                  isLoading: isLoading,
                                  onPressed: () => _submit(context),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
