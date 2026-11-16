import 'package:flutter/material.dart';

import 'package:changa_app/core/theme/app_colors.dart';
import 'package:changa_app/core/theme/app_spacing.dart';
import 'package:changa_app/features/chores/domain/entities/swap_request.dart';

/// Shown on the roster while a housemate is waiting for an answer to a swap
/// request. Shows the oldest-waiting one first; the rest follow once it is
/// answered.
class SwapRequestBanner extends StatelessWidget {
  const SwapRequestBanner({
    super.key,
    required this.requests,
    required this.titleOf,
    required this.nameOf,
    required this.respondingIds,
    required this.onRespond,
  });

  final List<SwapRequest> requests;
  final String Function(SwapRequest request) titleOf;
  final String Function(String uid) nameOf;
  final Set<String> respondingIds;
  final void Function(String requestId, {required bool accept}) onRespond;

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final request = requests.last;
    final busy = respondingIds.contains(request.id);
    final name = nameOf(request.fromUid).split(' ').first;
    final others = requests.length - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.athsSpecial,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.swap_horiz_rounded),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      '$name wants to swap ${titleOf(request)} with you',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (request.note != null && request.note!.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '“${request.note!.trim()}”',
                  style: theme.textTheme.bodySmall,
                ),
              ],
              if (others > 0) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '$others more waiting',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.edward,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: busy
                          ? null
                          : () => onRespond(request.id, accept: false),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        foregroundColor: AppColors.sherwoodGreen,
                      ),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton(
                      onPressed: busy
                          ? null
                          : () => onRespond(request.id, accept: true),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        backgroundColor: AppColors.lightGreen,
                        foregroundColor: AppColors.sherwoodGreen,
                      ),
                      child: busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Accept'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
