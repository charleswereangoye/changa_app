import 'package:flutter/material.dart';

import 'package:changa_app/core/theme/app_colors.dart';
import 'package:changa_app/core/theme/app_spacing.dart';
import 'package:changa_app/features/chores/domain/entities/chore.dart';

/// Easy / Medium / Hard, each showing the points it is worth.
class DifficultySelector extends StatelessWidget {
  const DifficultySelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
  });

  final ChoreDifficulty selected;
  final ValueChanged<ChoreDifficulty> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final difficulty in ChoreDifficulty.values) ...[
          if (difficulty != ChoreDifficulty.values.first)
            const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _DifficultyChip(
              difficulty: difficulty,
              isSelected: difficulty == selected,
              onTap: enabled ? () => onChanged(difficulty) : null,
            ),
          ),
        ],
      ],
    );
  }
}

class _DifficultyChip extends StatelessWidget {
  const _DifficultyChip({
    required this.difficulty,
    required this.isSelected,
    required this.onTap,
  });

  final ChoreDifficulty difficulty;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = isSelected ? AppColors.sherwoodGreen : AppColors.white;
    final foreground = isSelected ? AppColors.ginFizz : AppColors.sherwoodGreen;

    return Semantics(
      button: true,
      selected: isSelected,
      label: '${difficulty.label}, ${difficulty.credits} points',
      excludeSemantics: true,
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? AppColors.sherwoodGreen : AppColors.edward,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  difficulty.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${difficulty.credits} pts',
                  style: theme.textTheme.bodySmall?.copyWith(color: foreground),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
