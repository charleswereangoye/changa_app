import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';

class HousemateBalanceChip extends StatelessWidget {
  const HousemateBalanceChip({
    super.key,
    required this.displayName,
    required this.balance,
    this.onTap,
  });

  final String displayName;

  /// Positive: this person owes me. Negative: I owe this person.
  final int balance;

  final VoidCallback? onTap;

  String get _name {
    final trimmed = displayName.trim();
    return trimmed.isEmpty ? 'Former member' : trimmed;
  }

  String get _balanceLabel {
    final amount = CurrencyFormatter.format(balance.abs());

    if (balance > 0) return 'Owes you $amount';
    if (balance < 0) return 'You owe $amount';
    return 'All settled up';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Semantics(
      button: onTap != null,
      label: '$_name. $_balanceLabel',
      excludeSemantics: true,
      child: Tooltip(
        message: _name,
        child: Material(
          color: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: colors.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64, maxWidth: 280),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: colors.primaryContainer,
                      foregroundColor: colors.onPrimaryContainer,
                      child: const Icon(Icons.person_outline_rounded),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            _balanceLabel,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (onTap != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: colors.onSurfaceVariant,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
