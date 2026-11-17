import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:changa_app/core/theme/app_colors.dart';
import 'package:changa_app/core/theme/app_spacing.dart';
import 'package:changa_app/core/theme/app_text_styles.dart';
import 'package:changa_app/core/utils/currency_formatter.dart';
import 'package:changa_app/features/activity/domain/entities/activity.dart';
import 'package:changa_app/features/dashboard/presentation/cubit/dashboard_cubit.dart';

class RecentActivityList extends StatelessWidget {
  const RecentActivityList({
    super.key,
    required this.status,
    required this.items,
    required this.names,
    required this.currentUid,
    required this.onSeeAll,
    this.now,
  });

  final DashboardSection status;
  final List<Activity> items;
  final Map<String, String> names;
  final String? currentUid;
  final VoidCallback onSeeAll;
  final DateTime? now;

  static String describe(
    Activity activity, {
    required String? currentUid,
    required Map<String, String> names,
  }) {
    String who(String? uid) {
      if (uid == null) return 'A housemate';
      if (uid == currentUid) return 'You';
      return names[uid] ?? 'A housemate';
    }

    String whom(String? uid) {
      if (uid == null) return 'a housemate';
      if (uid == currentUid) return 'you';
      return names[uid] ?? 'a housemate';
    }

    final actor = who(activity.actorUid);
    final amount = activity.amount == null
        ? ''
        : ' of ${CurrencyFormatter.format(activity.amount!)}';

    return switch (activity.type) {
      ActivityType.expenseAdded => '$actor added an expense$amount',
      ActivityType.expenseDeleted => '$actor deleted an expense',
      ActivityType.debtSettled =>
        '$actor settled up with ${whom(activity.targetUid)}',
      ActivityType.choreCompleted => '$actor finished a chore',
      ActivityType.memberJoined => '$actor joined the household',
      ActivityType.memberRemoved =>
        '$actor removed ${whom(activity.targetUid)} from the household',
      ActivityType.swapRequested =>
        '$actor asked ${whom(activity.targetUid)} to swap a chore',
      ActivityType.swapAccepted => '$actor accepted a chore swap',
      ActivityType.nudgeSent =>
        '$actor sent ${whom(activity.targetUid)} a friendly nudge',
    };
  }

  static String timeAgo(DateTime then, DateTime now) {
    final diff = now.difference(then);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return DateFormat('d MMM').format(then);
  }

  static IconData _icon(ActivityType type) => switch (type) {
    ActivityType.expenseAdded => Icons.receipt_long_outlined,
    ActivityType.expenseDeleted => Icons.delete_outline,
    ActivityType.debtSettled => Icons.handshake_outlined,
    ActivityType.choreCompleted => Icons.check_circle_outline,
    ActivityType.memberJoined => Icons.person_add_alt_outlined,
    ActivityType.memberRemoved => Icons.person_remove_outlined,
    ActivityType.swapRequested => Icons.swap_horiz,
    ActivityType.swapAccepted => Icons.swap_horiz,
    ActivityType.nudgeSent => Icons.notifications_none,
  };

  @override
  Widget build(BuildContext context) {
    final reference = now ?? DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('Recent activity', style: AppTextStyles.bodyLarge),
            ),
            TextButton(
              key: const Key('activity-see-all'),
              onPressed: onSeeAll,
              child: const Text('See all'),
            ),
          ],
        ),
        switch (status) {
          DashboardSection.loading => const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Center(child: CircularProgressIndicator()),
          ),
          DashboardSection.failed => const Text(
            "Couldn't load recent activity.",
            style: AppTextStyles.bodyMedium,
          ),
          DashboardSection.ready =>
            items.isEmpty
                ? const Text(
                    'Nothing yet. Add the first expense or chore.',
                    key: Key('activity-empty'),
                    style: AppTextStyles.bodyMedium,
                  )
                : Column(
                    children: [
                      for (final item in items)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sm,
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.athsSpecial,
                                child: Icon(
                                  _icon(item.type),
                                  size: 18,
                                  color: AppColors.sherwoodGreen,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Text(
                                  describe(
                                    item,
                                    currentUid: currentUid,
                                    names: names,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.bodyMedium,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                timeAgo(item.createdAt, reference),
                                style: AppTextStyles.bodySmall,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
        },
      ],
    );
  }
}
