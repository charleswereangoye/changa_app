// Owner: B - Person B (Database Design, Security Rules, Household, Activity Feed)
// Description: Pure function formatting activity events into human-readable text

import 'package:intl/intl.dart';
import 'package:changa_app/core/utils/currency_formatter.dart';
import 'package:changa_app/features/activity/domain/entities/activity.dart';

class ActivityMessageBuilder {
  const ActivityMessageBuilder._();

  static const String fallbackMemberName = 'Former member';

  /// Pure function turning an [Activity] and a [memberNames] map into a
  /// single human-readable sentence such as:
  /// `"Amara added Groceries, RWF 24,000"` or `"Amara settled with Kevin, RWF 4,000"`.
  static String build(
    Activity activity,
    Map<String, String> memberNames, {
    String? currentUid,
    String? itemTitle,
    Map<String, String>? refTitles,
  }) {
    final actor = resolveName(
      activity.actorUid,
      memberNames,
      currentUid: currentUid,
    );
    final target = resolveName(
      activity.targetUid,
      memberNames,
      currentUid: currentUid,
      lowercaseYou: true,
    );
    final resolvedTitle = _resolveItemTitle(
      activity,
      itemTitle: itemTitle,
      refTitles: refTitles,
    );
    final amountText = _formatAmountSuffix(activity);

    return switch (activity.type) {
      ActivityType.expenseAdded =>
        resolvedTitle != null
            ? '$actor added $resolvedTitle$amountText'
            : '$actor added an expense$amountText',
      ActivityType.expenseDeleted =>
        resolvedTitle != null
            ? '$actor deleted $resolvedTitle$amountText'
            : '$actor deleted an expense$amountText',
      ActivityType.debtSettled =>
        activity.targetUid != null && activity.targetUid!.trim().isNotEmpty
            ? '$actor settled with $target$amountText'
            : '$actor settled a debt$amountText',
      ActivityType.choreCompleted =>
        resolvedTitle != null
            ? '$actor completed $resolvedTitle${_formatPointsSuffix(activity)}'
            : '$actor completed a chore${_formatPointsSuffix(activity)}',
      ActivityType.memberJoined => '$actor joined the household',
      ActivityType.memberRemoved =>
        activity.targetUid != null && activity.targetUid!.trim().isNotEmpty
            ? '$target was removed from the household'
            : '$actor removed a member from the household',
      ActivityType.swapRequested =>
        activity.targetUid != null && activity.targetUid!.trim().isNotEmpty
            ? '$actor requested a chore swap with $target'
            : '$actor requested a chore swap',
      ActivityType.swapAccepted =>
        activity.targetUid != null && activity.targetUid!.trim().isNotEmpty
            ? '$actor accepted a chore swap with $target'
            : '$actor accepted a chore swap',
      ActivityType.nudgeSent =>
        activity.targetUid != null && activity.targetUid!.trim().isNotEmpty
            ? 'Nudge sent to $target'
            : '$actor sent a nudge',
    };
  }

  /// Formats the primary headline shown on an `ActivityTile` card.
  static String formatCardTitle(
    Activity activity,
    Map<String, String> memberNames, {
    String? currentUid,
    String? itemTitle,
    Map<String, String>? refTitles,
  }) {
    final actor = resolveName(
      activity.actorUid,
      memberNames,
      currentUid: currentUid,
    );
    final target = resolveName(
      activity.targetUid,
      memberNames,
      currentUid: currentUid,
      lowercaseYou: true,
    );
    final resolvedTitle = _resolveItemTitle(
      activity,
      itemTitle: itemTitle,
      refTitles: refTitles,
    );

    return switch (activity.type) {
      ActivityType.expenseAdded => resolvedTitle ?? '$actor added an expense',
      ActivityType.expenseDeleted =>
        resolvedTitle != null
            ? 'Deleted $resolvedTitle'
            : '$actor deleted an expense',
      ActivityType.debtSettled =>
        activity.targetUid != null && activity.targetUid!.trim().isNotEmpty
            ? (activity.actorUid == currentUid
                  ? 'Settled with $target'
                  : '$actor settled with $target')
            : '$actor settled a debt',
      ActivityType.choreCompleted =>
        resolvedTitle != null
            ? '$resolvedTitle completed'
            : '$actor completed a chore',
      ActivityType.memberJoined => '$actor joined the household',
      ActivityType.memberRemoved =>
        activity.targetUid != null && activity.targetUid!.trim().isNotEmpty
            ? '$target was removed'
            : 'Member removed from household',
      ActivityType.swapRequested =>
        activity.targetUid != null && activity.targetUid!.trim().isNotEmpty
            ? 'Swap requested with $target'
            : '$actor requested a chore swap',
      ActivityType.swapAccepted =>
        activity.targetUid != null && activity.targetUid!.trim().isNotEmpty
            ? 'Swap accepted with $target'
            : '$actor accepted a chore swap',
      ActivityType.nudgeSent =>
        activity.targetUid != null && activity.targetUid!.trim().isNotEmpty
            ? 'Nudge sent to $target'
            : 'Nudge sent',
    };
  }

  /// Formats the secondary subtitle line (e.g. `"Paid by Jean · 2h ago"` or `"By you · 4h ago"`).
  static String formatCardSubtitle(
    Activity activity,
    Map<String, String> memberNames, {
    String? currentUid,
    DateTime? now,
  }) {
    final isActorMe =
        currentUid != null &&
        currentUid.isNotEmpty &&
        activity.actorUid == currentUid;
    final actorName = isActorMe
        ? 'you'
        : resolveName(activity.actorUid, memberNames);
    final timeLabel = formatRelativeTime(activity.createdAt, now: now);

    final prefix = switch (activity.type) {
      ActivityType.expenseAdded => 'Paid by $actorName',
      ActivityType.expenseDeleted => 'Deleted by $actorName',
      ActivityType.debtSettled => 'By $actorName',
      ActivityType.choreCompleted => 'By $actorName',
      ActivityType.memberJoined => 'New roommate',
      ActivityType.memberRemoved => 'By $actorName',
      ActivityType.swapRequested => 'By $actorName',
      ActivityType.swapAccepted => 'By $actorName',
      ActivityType.nudgeSent => 'By $actorName',
    };

    return '$prefix · $timeLabel';
  }

  /// Formats the right-side trailing badge (e.g. `"RWF 12,000"`, `"+10 pts"`, `"Sent"`).
  static String? formatTrailingBadge(Activity activity) {
    switch (activity.type) {
      case ActivityType.expenseAdded:
      case ActivityType.expenseDeleted:
      case ActivityType.debtSettled:
        if (activity.amount != null && activity.amount! >= 0) {
          return CurrencyFormatter.format(activity.amount!);
        }
        return null;
      case ActivityType.choreCompleted:
        if (activity.amount != null && activity.amount! > 0) {
          return '+${activity.amount} pts';
        }
        return null;
      case ActivityType.nudgeSent:
        return 'Sent';
      case ActivityType.memberJoined:
      case ActivityType.memberRemoved:
      case ActivityType.swapRequested:
      case ActivityType.swapAccepted:
        return null;
    }
  }

  static String resolveName(
    String? uid,
    Map<String, String> memberNames, {
    String? currentUid,
    bool lowercaseYou = false,
  }) {
    final cleanUid = uid?.trim() ?? '';
    if (cleanUid.isEmpty) return fallbackMemberName;

    if (currentUid != null &&
        currentUid.isNotEmpty &&
        cleanUid == currentUid.trim()) {
      return lowercaseYou ? 'you' : 'You';
    }

    final rawName = memberNames[cleanUid]?.trim();
    if (rawName != null && rawName.isNotEmpty) {
      return rawName;
    }
    return fallbackMemberName;
  }

  static String formatRelativeTime(DateTime dateTime, {DateTime? now}) {
    final reference = (now ?? DateTime.now()).toLocal();
    final local = dateTime.toLocal();
    final diff = reference.difference(local);

    final today = DateTime(reference.year, reference.month, reference.day);
    final targetDay = DateTime(local.year, local.month, local.day);
    final dayDiff = today.difference(targetDay).inDays;

    if (diff.inSeconds < 60 && dayDiff <= 0) {
      return 'Just now';
    }
    if (diff.inMinutes < 60 && dayDiff == 0) {
      return '${diff.inMinutes}m ago';
    }
    if (diff.inHours < 24 && dayDiff == 0) {
      return '${diff.inHours}h ago';
    }
    if (dayDiff == 1) {
      return 'Yesterday';
    }
    if (dayDiff > 1 && dayDiff < 7) {
      return '$dayDiff days';
    }
    return DateFormat('d MMM').format(local);
  }

  static String? _resolveItemTitle(
    Activity activity, {
    String? itemTitle,
    Map<String, String>? refTitles,
  }) {
    final direct = itemTitle?.trim();
    if (direct != null && direct.isNotEmpty) {
      return direct;
    }
    final refId = activity.refId?.trim();
    if (refId != null && refId.isNotEmpty && refTitles != null) {
      final mapped = refTitles[refId]?.trim();
      if (mapped != null && mapped.isNotEmpty) {
        return mapped;
      }
    }
    return null;
  }

  static String _formatAmountSuffix(Activity activity) {
    if (activity.amount != null && activity.amount! >= 0) {
      return ', ${CurrencyFormatter.format(activity.amount!)}';
    }
    return '';
  }

  static String _formatPointsSuffix(Activity activity) {
    if (activity.amount != null && activity.amount! > 0) {
      return ' (+${activity.amount} pts)';
    }
    return '';
  }
}
