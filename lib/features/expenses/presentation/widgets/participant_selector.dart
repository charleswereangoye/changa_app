// Owner: C - Person C (Expenses, Dashboard, Documentation)
// Description: Row of member avatars to pick who paid or who shares a cost

import 'package:flutter/material.dart';

import 'package:changa_app/core/theme/app_colors.dart';
import 'package:changa_app/core/theme/app_spacing.dart';
import 'package:changa_app/core/theme/app_text_styles.dart';
import 'package:changa_app/core/widgets/member_avatar.dart';
import 'package:changa_app/features/expenses/presentation/cubit/add_expense_state.dart';

/// Used twice on the form: once to pick the payer (one selected) and once to
/// pick who shares the cost (many selected).
class ParticipantSelector extends StatelessWidget {
  const ParticipantSelector({
    super.key,
    required this.participants,
    required this.selectedUids,
    required this.onTap,
    this.keyPrefix = 'participant',
  });

  final List<ExpenseParticipant> participants;
  final List<String> selectedUids;
  final ValueChanged<String> onTap;

  /// Each avatar gets the key "$keyPrefix-$uid", which the tests use.
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [for (final person in participants) _item(person)],
    );
  }

  Widget _item(ExpenseParticipant person) {
    final selected = selectedUids.contains(person.uid);

    return Semantics(
      button: true,
      selected: selected,
      label: person.name,
      child: InkWell(
        key: ValueKey('$keyPrefix-${person.uid}'),
        borderRadius: BorderRadius.circular(12),
        onTap: () => onTap(person.uid),
        child: SizedBox(
          width: 64,
          child: Opacity(
            opacity: selected ? 1 : 0.45,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MemberAvatar(
                  uid: person.uid,
                  name: person.name,
                  radius: 22,
                  isSelected: selected,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _firstName(person.name),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.sherwoodGreen,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _firstName(String name) {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '?' : trimmed.split(RegExp(r'\s+')).first;
  }
}
