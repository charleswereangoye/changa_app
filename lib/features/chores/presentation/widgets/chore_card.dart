import 'package:flutter/material.dart';

import 'package:changa_app/core/theme/app_colors.dart';
import 'package:changa_app/core/theme/app_spacing.dart';
import 'package:changa_app/core/utils/date_helpers.dart';
import 'package:changa_app/core/widgets/credit_badge.dart';
import 'package:changa_app/features/chores/domain/entities/chore.dart';

/// One chore on the roster. Your own open chores get the action buttons.
class ChoreCard extends StatelessWidget {
  const ChoreCard({
    super.key,
    required this.chore,
    required this.assigneeName,
    required this.isMine,
    this.isMissed = false,
    this.isCompleting = false,
    this.now,
    this.onComplete,
    this.onEdit,
    this.onSwap,
  });

  final Chore chore;

  /// "You" for your own chores, otherwise the housemate's first name.
  final String assigneeName;
  final bool isMine;
  final bool isMissed;
  final bool isCompleting;

  /// Only here so tests can pin "today".
  final DateTime? now;
  final VoidCallback? onComplete;
  final VoidCallback? onEdit;
  final VoidCallback? onSwap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final showActions = isMine && !chore.isDone;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LeadingIcon(done: chore.isDone),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chore.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration: chore.isDone
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _Subtitle(
                        assigneeName: assigneeName,
                        dueLabel: _dueLabel(),
                        isMissed: isMissed && !chore.isDone,
                        isDone: chore.isDone,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                CreditBadge(
                  credits: chore.creditsAwarded ?? chore.difficulty.credits,
                ),
              ],
            ),
            if (showActions) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: isCompleting ? null : onComplete,
                      icon: isCompleting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_rounded, size: 20),
                      label: const Text('Mark Done'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                        backgroundColor: scheme.primary,
                        foregroundColor: scheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  if (onSwap != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    _RoundAction(
                      tooltip: 'Swap this chore',
                      icon: Icons.swap_horiz_rounded,
                      onPressed: isCompleting ? null : onSwap,
                    ),
                  ],
                  if (onEdit != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    _RoundAction(
                      tooltip: 'Edit chore',
                      icon: Icons.edit_outlined,
                      onPressed: isCompleting ? null : onEdit,
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _dueLabel() {
    final today = DateHelpers.startOfDay(now ?? DateTime.now());
    final due = DateHelpers.startOfDay(chore.dueDate);
    if (due == today) return 'Due today';
    if (due == DateHelpers.addDays(today, 1)) return 'Due tomorrow';
    if (due == DateHelpers.addDays(today, -1)) return 'Due yesterday';
    return 'Due ${DateHelpers.dayLabel(chore.dueDate)}';
  }
}

class _LeadingIcon extends StatelessWidget {
  const _LeadingIcon({required this.done});

  final bool done;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: done ? AppColors.leafGreen : AppColors.athsSpecial,
        shape: BoxShape.circle,
      ),
      child: SizedBox(
        width: 40,
        height: 40,
        child: Icon(
          done ? Icons.check_rounded : Icons.cleaning_services_outlined,
          size: 20,
          color: done ? AppColors.white : AppColors.sherwoodGreen,
        ),
      ),
    );
  }
}

class _Subtitle extends StatelessWidget {
  const _Subtitle({
    required this.assigneeName,
    required this.dueLabel,
    required this.isMissed,
    required this.isDone,
  });

  final String assigneeName;
  final String dueLabel;
  final bool isMissed;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    final detail = isDone ? 'Done' : (isMissed ? 'Missed' : dueLabel);

    return Text(
      '$assigneeName · $detail',
      style: style?.copyWith(
        color: isMissed ? AppColors.sunglo : AppColors.edward,
        fontWeight: isMissed ? FontWeight.w600 : null,
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      style: IconButton.styleFrom(
        backgroundColor: AppColors.athsSpecial,
        foregroundColor: AppColors.sherwoodGreen,
        minimumSize: const Size(44, 44),
      ),
    );
  }
}
