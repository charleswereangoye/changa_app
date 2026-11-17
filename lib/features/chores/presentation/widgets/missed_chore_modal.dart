import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:changa_app/core/utils/date_helpers.dart';
import 'package:changa_app/core/widgets/alert_modal.dart';
import 'package:changa_app/features/chores/domain/entities/chore.dart';
import 'package:changa_app/features/chores/presentation/cubit/missed_chore_cubit.dart';

/// The reminder about a chore that went past its day.
class MissedChoreModal extends StatelessWidget {
  const MissedChoreModal({super.key, required this.chore, this.otherCount = 0});

  final Chore chore;
  final int otherCount;

  /// Opens the reminder for whatever [cubit] is currently asking about.
  static Future<void> show(BuildContext context, MissedChoreCubit cubit) {
    final prompt = cubit.state.prompt;
    if (prompt == null) return Future.value();

    return showDialog<void>(
      context: context,
      builder: (_) => BlocProvider<MissedChoreCubit>.value(
        value: cubit,
        child: MissedChoreModal(
          chore: prompt,
          otherCount: cubit.state.otherCount,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MissedChoreCubit>();
    final more = otherCount == 0
        ? ''
        : otherCount == 1
        ? ' You have 1 more missed chore.'
        : ' You have $otherCount more missed chores.';

    return AlertModal(
      icon: Icons.schedule_rounded,
      title: 'You missed a chore',
      body:
          '${chore.title} was due ${DateHelpers.dayLabel(chore.dueDate)}. '
          'You can still finish it and earn ${chore.difficulty.credits} pts.'
          '$more',
      primaryText: 'Mark Done',
      onPrimaryPressed: () {
        Navigator.of(context).pop();
        cubit.completePrompt();
      },
      dismissText: 'Dismiss',
      onDismiss: () {
        Navigator.of(context).pop();
        cubit.dismiss();
      },
    );
  }
}
