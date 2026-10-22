import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../injection_container.dart';
import '../cubit/sign_up_cubit.dart';
import '../widgets/auth_back_button.dart';
import '../widgets/social_auth_button.dart';

/// Screen allowing new users to create their Changa account.
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<SignUpCubit>().signUp(
        fullName: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        password: _passwordController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl.isRegistered<SignUpCubit>() ? sl<SignUpCubit>() : SignUpCubit(),
      child: Scaffold(
        backgroundColor: AppColors.ginFizz,
        body: SafeArea(
          child: BlocConsumer<SignUpCubit, SignUpState>(
            listener: (context, state) {
              if (state.isSuccess) {
                context.goNamed(RouteNames.createHousehold);
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

                          // Heading & Subtitle matching Figma
                          const Text(
                            'Create your account',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.sherwoodGreen,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Join your household in minutes',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: AppColors.edward,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Full Name
                          AppTextField(
                            label: 'Full Name',
                            hintText: 'e.g. Amara Okoye',
                            controller: _nameController,
                            prefixIcon: const Icon(
                              Icons.person_outline_rounded,
                              color: AppColors.edward,
                              size: 20,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

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

                          // Phone Number
                          AppTextField(
                            label: 'Phone Number',
                            hintText: '+250 7XX XXX XXX',
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            prefixIcon: const Icon(
                              Icons.phone_outlined,
                              color: AppColors.edward,
                              size: 20,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your phone number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Password
                          AppTextField(
                            label: 'Password',
                            hintText: 'Create a password',
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
                                    .read<SignUpCubit>()
                                    .togglePasswordVisibility();
                              },
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please create a password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Terms & Privacy Notice
                          const Text(
                            'By continuing you agree to our Terms & Privacy Policy.',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: AppColors.edward,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Create Account Button
                          PrimaryButton(
                            text: 'Create Account',
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
                                        .read<SignUpCubit>()
                                        .signUpWithGoogle();
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: SocialAuthButton(
                                  label: 'Apple',
                                  onPressed: () {
                                    context
                                        .read<SignUpCubit>()
                                        .signUpWithApple();
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Bottom link to Login
                          Center(
                            child: GestureDetector(
                              onTap: () {
                                if (context.canPop()) {
                                  context.pop();
                                } else {
                                  context.pushNamed(RouteNames.login);
                                }
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 4),
                                child: Text.rich(
                                  TextSpan(
                                    text: 'Already have an account? ',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.edward,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Log In',
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
