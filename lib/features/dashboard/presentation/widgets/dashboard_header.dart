import 'package:flutter/material.dart';

import 'package:changa_app/core/theme/app_colors.dart';
import 'package:changa_app/core/theme/app_spacing.dart';
import 'package:changa_app/core/theme/app_text_styles.dart';
import 'package:changa_app/core/widgets/member_avatar.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.householdName,
    required this.uid,
    required this.displayName,
    this.onBell,
    this.onAvatar,
  });

  final String householdName;
  final String uid;
  final String displayName;
  final VoidCallback? onBell;
  final VoidCallback? onAvatar;

  static String firstName(String name) {
    final trimmed = name.trim();
    return trimmed.isEmpty ? 'there' : trimmed.split(RegExp(r'\s+')).first;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                householdName.toUpperCase(),
                key: const Key('dashboard-household'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall.copyWith(
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                  color: AppColors.sherwoodGreen,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Hi, ${firstName(displayName)} 👋',
                key: const Key('dashboard-greeting'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.heading2,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Material(
          color: AppColors.white,
          shape: const CircleBorder(),
          child: IconButton(
            key: const Key('dashboard-bell'),
            onPressed: onBell,
            tooltip: 'Notifications',
            icon: const Icon(
              Icons.notifications_none,
              color: AppColors.sherwoodGreen,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        InkWell(
          key: const Key('dashboard-avatar'),
          customBorder: const CircleBorder(),
          onTap: onAvatar,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: MemberAvatar(uid: uid, name: displayName, radius: 20),
            ),
          ),
        ),
      ],
    );
  }
}
