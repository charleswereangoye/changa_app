// Owner: A - Person A (Foundation, Authentication, Profile)
// Description: Settings list tile item matching Figma design system

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Clean settings tile for Profile & Settings screen matching Figma specifications.
class SettingsTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final String? badgeText;
  final bool isDestructive;
  final bool showDivider;
  final Widget? trailing;

  const SettingsTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.onTap,
    this.badgeText,
    this.isDestructive = false,
    this.showDivider = true,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    const snowDrift = Color(0xFFF0F4F2);
    final iconBgColor = isDestructive ? AppColors.vanillaIce : snowDrift;
    final iconColor = isDestructive
        ? AppColors.sunglo
        : AppColors.sherwoodGreen;
    final textColor = isDestructive
        ? AppColors.sunglo
        : AppColors.sherwoodGreen;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // Icon container
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 20, color: iconColor),
                  ),
                  const SizedBox(width: 14),

                  // Title and optional Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: AppColors.edward,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Optional Badge (e.g. "ADMIN")
                  if (badgeText != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.vanillaIce,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        badgeText!.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.sunglo,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],

                  // Trailing widget or Chevron
                  trailing ??
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: AppColors.edward,
                      ),
                ],
              ),
            ),
            if (showDivider)
              Padding(
                padding: const EdgeInsets.only(left: 68, right: 16),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.sherwoodGreen.withValues(alpha: 0.05),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
