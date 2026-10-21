import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

import 'package:go_router/go_router.dart';

/// The very first screen shown when opening Changa.
/// It displays the app logo, name, and tagline matching Figma.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Scaffold provides the main screen structure
    return Scaffold(
      backgroundColor: AppColors.sherwoodGreen,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          context.go('/onboarding');
        },
        child: Stack(
          children: [
            // Decorative top-left ring from Figma design
            Positioned(
              top: -100,
              left: -150,
              child: Container(
                width: 380,
                height: 380,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.ginFizz4, width: 1),
                ),
              ),
            ),

            // Decorative bottom-right ring from Figma design
            Positioned(
              bottom: -80,
              right: -100,
              child: Container(
                width: 500,
                height: 500,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.ginFizz4, width: 1),
                ),
              ),
            ),

            // Center content: Logo, App Name, and Tagline
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Outer semi-transparent ring from Figma
                    Container(
                      width: 96,
                      height: 96,
                      decoration: const BoxDecoration(
                        color: AppColors.sunglo15,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      // Inner solid green circle
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          color: AppColors.leafGreen,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        // House icon downloaded from Figma
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 28,
                          height: 28,
                          color: AppColors.ginFizz,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback icon if asset is not loaded yet
                            return const Icon(
                              Icons.home_rounded,
                              size: 28,
                              color: AppColors.ginFizz,
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // App Title
                    Text(
                      'Changa',
                      style: AppTextStyles.heading1.copyWith(
                        color: AppColors.ginFizz,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Tagline
                    Text(
                      'Live together, better.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.ginFizz.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom 3-dot loading indicator from Figma
            Positioned(
              left: 0,
              right: 0,
              bottom: 40,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Left dot (faded)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.leafGreen40,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Center dot (active)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.leafGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Right dot (faded)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.leafGreen40,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
