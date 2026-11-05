import 'package:flutter/material.dart';

/// The small "+20 pts" pill shown on chore cards and in the activity feed.
class CreditBadge extends StatelessWidget {
  const CreditBadge({super.key, required this.credits, this.showPlus = true});

  final int credits;

  /// Turn off to show a balance ("340 pts") instead of a reward.
  final bool showPlus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Semantics(
      label: '$credits credits',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Text(
            showPlus ? '+$credits pts' : '$credits pts',
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
