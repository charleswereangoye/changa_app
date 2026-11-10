// Activity feed row item matching Figma cards

import 'package:flutter/material.dart';
import 'package:changa_app/core/theme/app_colors.dart';
import 'package:changa_app/core/theme/app_spacing.dart';
import 'package:changa_app/features/activity/domain/activity_message_builder.dart';
import 'package:changa_app/features/activity/domain/entities/activity.dart';

class ActivityTile extends StatelessWidget {
  final Activity? activity;
  final Map<String, String> memberNames;
  final String? currentUid;
  final String? itemTitle;
  final Map<String, String>? refTitles;
  final DateTime? now;
  final VoidCallback? onTap;

  const ActivityTile({
    super.key,
    this.activity,
    this.memberNames = const {},
    this.currentUid,
    this.itemTitle,
    this.refTitles,
    this.now,
    this.onTap,
  });

  static IconData _iconForType(ActivityType type) {
    return switch (type) {
      ActivityType.expenseAdded => Icons.shopping_cart_outlined,
      ActivityType.expenseDeleted => Icons.receipt_long_outlined,
      ActivityType.debtSettled => Icons.balance_rounded,
      ActivityType.choreCompleted => Icons.done_all_rounded,
      ActivityType.memberJoined => Icons.person_add_alt_1_outlined,
      ActivityType.memberRemoved => Icons.person_remove_outlined,
      ActivityType.swapRequested => Icons.swap_horiz_rounded,
      ActivityType.swapAccepted => Icons.published_with_changes_rounded,
      ActivityType.nudgeSent => Icons.send_outlined,
    };
  }

  static Color _badgeBackgroundForType(ActivityType type) {
    return switch (type) {
      ActivityType.expenseAdded ||
      ActivityType.expenseDeleted ||
      ActivityType.nudgeSent => AppColors.sunglo.withValues(alpha: 0.16),
      ActivityType.debtSettled ||
      ActivityType.swapRequested => AppColors.goldSand.withValues(alpha: 0.35),
      ActivityType.choreCompleted ||
      ActivityType.memberJoined ||
      ActivityType.swapAccepted => AppColors.opal.withValues(alpha: 0.3),
      ActivityType.memberRemoved => AppColors.edward.withValues(alpha: 0.2),
    };
  }

  static Color _iconColorForType(ActivityType type) {
    return switch (type) {
      ActivityType.expenseAdded ||
      ActivityType.nudgeSent ||
      ActivityType.choreCompleted ||
      ActivityType.memberJoined ||
      ActivityType.swapAccepted => AppColors.leafGreen,
      ActivityType.expenseDeleted => AppColors.sunglo,
      ActivityType.debtSettled ||
      ActivityType.swapRequested ||
      ActivityType.memberRemoved => AppColors.sherwoodGreen,
    };
  }

  @override
  Widget build(BuildContext context) {
    final item = activity;
    if (item == null) {
      return const SizedBox.shrink();
    }

    final title = ActivityMessageBuilder.formatCardTitle(
      item,
      memberNames,
      currentUid: currentUid,
      itemTitle: itemTitle,
      refTitles: refTitles,
    );
    final subtitle = ActivityMessageBuilder.formatCardSubtitle(
      item,
      memberNames,
      currentUid: currentUid,
      now: now,
    );
    final trailing = ActivityMessageBuilder.formatTrailingBadge(item);
    final isMutedTrailing = item.type == ActivityType.nudgeSent;

    return Semantics(
      button: onTap != null,
      label: ActivityMessageBuilder.build(
        item,
        memberNames,
        currentUid: currentUid,
        itemTitle: itemTitle,
        refTitles: refTitles,
      ),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _badgeBackgroundForType(item.type),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _iconForType(item.type),
                    color: _iconColorForType(item.type),
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.sherwoodGreen,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
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
                if (trailing != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    flex: 0,
                    child: Text(
                      trailing,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: isMutedTrailing ? 12 : 14,
                        fontWeight: isMutedTrailing
                            ? FontWeight.w500
                            : FontWeight.w700,
                        color: isMutedTrailing
                            ? AppColors.edward
                            : AppColors.sherwoodGreen,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
