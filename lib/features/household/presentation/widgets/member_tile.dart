//  Household member list item with role badge

import 'package:flutter/material.dart';
import 'package:changa_app/core/theme/app_colors.dart';
import 'package:changa_app/core/theme/app_spacing.dart';
import 'package:changa_app/core/widgets/member_avatar.dart';
import 'package:changa_app/features/household/domain/entities/member.dart';

class MemberTile extends StatelessWidget {
  final Member? member;
  final String displayName;
  final int? harmonyScore;
  final bool isAdminRole;
  final bool showMenu;
  final bool enabled;
  final VoidCallback? onMorePressed;

  const MemberTile({
    super.key,
    this.member,
    this.displayName = 'Former member',
    this.harmonyScore,
    this.isAdminRole = false,
    this.showMenu = true,
    this.enabled = true,
    this.onMorePressed,
  });

  String get _resolvedName {
    final trimmed = displayName.trim();
    return trimmed.isEmpty ? 'Former member' : trimmed;
  }

  bool get _isAdmin => isAdminRole || member?.role == MemberRole.admin;

  String get _subtitle {
    if (harmonyScore != null) {
      return 'Harmony $harmonyScore';
    }
    final credits = member?.credits ?? 0;
    return 'Harmony — · $credits pts';
  }

  @override
  Widget build(BuildContext context) {
    final uid = member?.uid ?? '';

    return Container(
      key: uid.isNotEmpty ? ValueKey('member-tile-$uid') : null,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          MemberAvatar(uid: uid, name: _resolvedName, radius: 22),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.sm,
                  runSpacing: 4,
                  children: [
                    Text(
                      _resolvedName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.sherwoodGreen,
                      ),
                    ),
                    _RoleBadge(isAdmin: _isAdmin),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.edward,
                  ),
                ),
              ],
            ),
          ),
          if (showMenu)
            IconButton(
              key: uid.isNotEmpty ? ValueKey('member-menu-$uid') : null,
              tooltip: 'Member options for $_resolvedName',
              onPressed: enabled ? onMorePressed : null,
              icon: const Icon(
                Icons.more_vert_rounded,
                color: AppColors.edward,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final bool isAdmin;

  const _RoleBadge({required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isAdmin
        ? AppColors.vanillaIce
        : AppColors.athsSpecial;
    final textColor = isAdmin ? AppColors.leafGreen : AppColors.sherwoodGreen;
    final label = isAdmin ? 'ADMIN' : 'MEMBER';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: textColor,
        ),
      ),
    );
  }
}
