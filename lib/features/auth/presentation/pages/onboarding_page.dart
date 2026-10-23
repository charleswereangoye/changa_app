import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/primary_button.dart';
import '../cubit/onboarding_cubit.dart';
import '../cubit/onboarding_state.dart';
import '../widgets/onboarding_slide.dart';

/// The onboarding flow displaying 3 slides to introduce the app.
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OnboardingCubit(),
      child: const _OnboardingView(),
    );
  }
}

class _OnboardingView extends StatelessWidget {
  const _OnboardingView();

  void _finishOnboarding(BuildContext context) {
    context.read<OnboardingCubit>().completeOnboarding();
    context.go('/sign-up');
  }

  @override
  Widget build(BuildContext context) {
    final pageController = PageController();

    return Scaffold(
      backgroundColor: AppColors.ginFizz,
      body: SafeArea(
        child: BlocConsumer<OnboardingCubit, OnboardingState>(
          listener: (context, state) {
            if (pageController.hasClients &&
                pageController.page?.round() != state.currentPage) {
              pageController.animateToPage(
                state.currentPage,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          },
          builder: (context, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),

                // Top Skip button aligned to top-left matching Figma
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => _finishOnboarding(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 8,
                        ),
                        minimumSize: const Size(48, 48),
                      ),
                      child: Text(
                        'Skip',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.edward,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

                // Carousel slides in middle (takes up remaining space)
                Expanded(
                  child: PageView(
                    controller: pageController,
                    onPageChanged: (index) {
                      context.read<OnboardingCubit>().setPage(index);
                    },
                    children: [
                      // Slide 1: Split expenses
                      OnboardingSlide(
                        illustration: Image.asset(
                          'assets/images/onboarding_1.png',
                          width: 90,
                          height: 90,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.group_rounded,
                              size: 80,
                              color: AppColors.lightGreen,
                            );
                          },
                        ),
                        title: 'Split expenses,\nnot friendships',
                        description: 'Track shared costs, split bills fairly, and always know who owes what — no awkward conversations needed.',
                      ),

                      // Slide 2: Chore roster
                      const OnboardingSlide(
                        illustration: Icon(
                          Icons.checklist_rounded,
                          size: 80,
                          color: AppColors.lightGreen,
                        ),
                        title: 'Fair chores,\nreal rewards',
                        description: 'Earn credits (pts) by completing chores. Swap fairly, and build a track record your roommates can see.',
                      ),

                      // Slide 3: Harmony score
                      const OnboardingSlide(
                        illustration: Icon(
                          Icons.eco_rounded,
                          size: 80,
                          color: AppColors.lightGreen,
                        ),
                        title: 'Keep the house\nin harmony',
                        description: 'Reflects how balanced your household is — fair splitting and chores done on time all contribute positively.',
                      ),
                    ],
                  ),
                ),

                // Bottom section pinned at screen bottom (Dots + Next Button + Sign In link)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Indicator dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (index) {
                          final isActive = state.currentPage == index;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: isActive ? 18 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.lightGreen
                                  : AppColors.inactiveDot,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 24),

                      // Next / Get Started button
                      PrimaryButton(
                        text: state.isLastPage ? 'Get Started' : 'Next',
                        onPressed: () {
                          if (state.isLastPage) {
                            _finishOnboarding(context);
                          } else {
                            pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                      ),

                      const SizedBox(height: 16),

                      // Bottom Sign In link
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            context.push('/login');
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text.rich(
                              TextSpan(
                                text: 'Already have an account? ',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.edward,
                                  fontSize: 13,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Sign In',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.sherwoodGreen,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
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
              ],
            );
          },
        ),
      ),
    );
  }
}
