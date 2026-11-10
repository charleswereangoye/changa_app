// Date grouping sticky header for activity stream

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:changa_app/core/theme/app_colors.dart';
import 'package:changa_app/core/theme/app_spacing.dart';

class DateGroupHeader extends StatelessWidget {
  final DateTime? date;
  final String? label;
  final DateTime? now;

  const DateGroupHeader({super.key, this.date, this.label, this.now});

  /// Formats [date] into `"Today"`, `"Yesterday"`, or `"12 Oct"` per B10 spec.
  static String formatLabel(DateTime date, {DateTime? now}) {
    final reference = (now ?? DateTime.now()).toLocal();
    final local = date.toLocal();

    final today = DateTime(reference.year, reference.month, reference.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final target = DateTime(local.year, local.month, local.day);

    if (target == today) {
      return 'Today';
    }
    if (target == yesterday) {
      return 'Yesterday';
    }
    if (local.year == reference.year) {
      return DateFormat('d MMM').format(local);
    }
    return DateFormat('d MMM yyyy').format(local);
  }

  @override
  Widget build(BuildContext context) {
    final resolvedLabel =
        label ?? (date != null ? formatLabel(date!, now: now) : '');
    if (resolvedLabel.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      color: AppColors.ginFizz,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.sm,
      ),
      alignment: Alignment.centerLeft,
      child: Text(
        resolvedLabel,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
          color: AppColors.edward,
        ),
      ),
    );
  }
}

class StickyDateHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String label;

  const StickyDateHeaderDelegate({required this.label});

  @override
  double get minExtent => 36;

  @override
  double get maxExtent => 36;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: DateGroupHeader(label: label));
  }

  @override
  bool shouldRebuild(covariant StickyDateHeaderDelegate oldDelegate) {
    return oldDelegate.label != label;
  }
}
