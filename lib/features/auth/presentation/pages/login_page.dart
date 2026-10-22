import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../injection_container.dart';
import '../cubit/login_cubit.dart';
import '../widgets/auth_back_button.dart';
import '../widgets/social_auth_button.dart';

/// Screen allowing existing users to log in to their Changa account.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<LoginCubit>().login(
        email: _emailController.text,
        password: _passwordController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl.isRegistered<LoginCubit>() ? sl<LoginCubit>() : LoginCubit(),
      child: Scaffold(
        backgroundColor: AppColors.ginFizz,
        body: SafeArea(
          child: BlocConsumer<LoginCubit, LoginState>(
            listener: (context, state) {
              if (state.isSuccess) {
                context.goNamed(RouteNames.dashboard);
              } else if (state.isFailure && state.errorMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.errorMessage!),
                    backgroundColor: AppColors.sunglo,
                  ),
                );
              }
            },
            builder: (context, state) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top circular back button with fallback navigation
                          const AuthBackButton(fallbackLocation: '/onboarding'),
                          const SizedBox(height: 16),

                          // Heading & Subtitle
                          const Text(
                            'Welcome back',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.sherwoodGreen,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Log in to your account to continue',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: AppColors.edward,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Email Address
                          AppTextField(
                            label: 'Email Address',
                            hintText: 'you@school.edu',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: const Icon(
                              Icons.mail_outline_rounded,
                              color: AppColors.edward,
                              size: 20,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!value.contains('@') ||
                                  !value.contains('.')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Password
                          AppTextField(
                            label: 'Password',
                            hintText: 'Enter your password',
                            controller: _passwordController,
                            obscureText: !state.isPasswordVisible,
                            prefixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              color: AppColors.edward,
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                state.isPasswordVisible
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.edward,
                                size: 20,
                              ),
                              onPressed: () {
                                context
                                    .read<LoginCubit>()
                                    .togglePasswordVisibility();
                              },
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),

                          // Forgot Password Link
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                context.pushNamed(RouteNames.forgotPassword);
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 4,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.sherwoodGreen,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Log In Button
                          PrimaryButton(
                            text: 'Log In',
                            isLoading: state.isLoading,
                            onPressed: () => _submit(context),
                          ),
                          const SizedBox(height: 16),

                          // Divider "or continue with"
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: AppColors.edward.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'or continue with',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.edward,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: AppColors.edward.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Social Buttons (Google & Apple)
                          Row(
                            children: [
                              Expanded(
                                child: SocialAuthButton(
                                  label: 'Google',
                                  onPressed: () {
                                    context
                                        .read<LoginCubit>()
                                        .loginWithGoogle();
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: SocialAuthButton(
                                  label: 'Apple',
                                  onPressed: () {
                                    context.read<LoginCubit>().loginWithApple();
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Bottom link to Sign Up
                          Center(
                            child: GestureDetector(
                              onTap: () {
                                context.pushNamed(RouteNames.signUp);
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 4),
                                child: Text.rich(
                                  TextSpan(
                                    text: "Don't have an account? ",
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.edward,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Sign Up',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.sherwoodGreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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
          ),
        ),
      ),
    );
  }
}
