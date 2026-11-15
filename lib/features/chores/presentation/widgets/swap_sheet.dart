import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'package:changa_app/core/theme/app_colors.dart';
import 'package:changa_app/core/theme/app_spacing.dart';
import 'package:changa_app/core/widgets/app_snackbar.dart';
import 'package:changa_app/core/widgets/member_avatar.dart';
import 'package:changa_app/features/chores/domain/entities/chore.dart';
import 'package:changa_app/features/chores/domain/usecases/request_swap.dart';
import 'package:changa_app/features/chores/domain/usecases/watch_all_chores.dart';
import 'package:changa_app/features/chores/presentation/cubit/swap_cubit.dart';

/// "Swap this chore": pick a housemate and send them a request. Needs a
/// [SwapCubit] above it; [SwapSheet.show] creates one.
class SwapSheet extends StatelessWidget {
  const SwapSheet({super.key});

  static Future<void> show(
    BuildContext context, {
    required Chore chore,
    required String householdId,
    required List<SwapCandidate> candidates,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (_) => BlocProvider<SwapCubit>(
        create: (_) => SwapCubit(
          requestSwap: GetIt.I<RequestSwap>(),
          watchAllChores: GetIt.I<WatchAllChores>(),
          householdId: householdId,
          chore: chore,
          candidates: candidates,
        )..load(),
        child: const SwapSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SwapCubit>();
    final theme = Theme.of(context);

    return BlocConsumer<SwapCubit, SwapState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == SwapFormStatus.sent) {
          AppSnackbar.success(context, state.message ?? 'Request sent.');
          Navigator.of(context).pop();
        } else if (state.status == SwapFormStatus.failure) {
          AppSnackbar.error(
            context,
            state.message ?? 'Couldn’t send the request.',
          );
        }
      },
      builder: (context, state) {
        final busy = state.isSending;

        return PopScope(
          canPop: !busy,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Swap this chore',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  cubit.chore.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.edward,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (state.candidates.isEmpty)
                  Text(
                    'There is nobody else in the household to swap with yet.',
                    style: theme.textTheme.bodyMedium,
                  )
                else
                  for (final person in state.candidates)
                    _PersonRow(
                      person: person,
                      count: state.countFor(person.uid),
                      isSending: state.sendingUid == person.uid,
                      enabled: !busy,
                      onRequest: () => cubit.request(person.uid),
                    ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  key: const Key('swap-note-field'),
                  enabled: !busy,
                  textCapitalization: TextCapitalization.sentences,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(SwapCubit.maxNoteLength),
                  ],
                  onChanged: cubit.noteChanged,
                  decoration: InputDecoration(
                    labelText: 'Add a note (optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({
    required this.person,
    required this.count,
    required this.isSending,
    required this.enabled,
    required this.onRequest,
  });

  final SwapCandidate person;
  final int count;
  final bool isSending;
  final bool enabled;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chores = count == 1 ? '1 chore this week' : '$count chores this week';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          MemberAvatar(uid: person.uid, name: person.name),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  person.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  chores,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.edward,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          FilledButton(
            onPressed: enabled ? onRequest : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size(48, 48),
              backgroundColor: AppColors.lightGreen,
              foregroundColor: AppColors.sherwoodGreen,
            ),
            child: isSending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Request Swap'),
          ),
        ],
      ),
    );
  }
}
