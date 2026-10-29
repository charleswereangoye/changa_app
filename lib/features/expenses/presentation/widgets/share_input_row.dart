// Owner: C - Person C (Expenses, Dashboard, Documentation)
// Description: One row of the percent / exact split: avatar, name, number box

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:changa_app/core/theme/app_colors.dart';
import 'package:changa_app/core/theme/app_spacing.dart';
import 'package:changa_app/core/theme/app_text_styles.dart';
import 'package:changa_app/core/widgets/member_avatar.dart';
import 'package:changa_app/features/expenses/domain/entities/split_type.dart';
import 'package:changa_app/features/expenses/presentation/cubit/add_expense_state.dart';

class ShareInputRow extends StatelessWidget {
  const ShareInputRow({
    super.key,
    required this.participant,
    required this.splitType,
    required this.initialText,
    required this.onChanged,
  });

  final ExpenseParticipant participant;

  /// Percent shows a "%" suffix, exact shows "RWF".
  final SplitType splitType;
  final String initialText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          MemberAvatar(
            uid: participant.uid,
            name: participant.name,
            radius: 16,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              participant.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMedium,
            ),
          ),
          SizedBox(
            width: 120,
            child: TextFormField(
              // The split type is in the key so the box resets when it changes.
              key: ValueKey('share-${participant.uid}-${splitType.name}'),
              initialValue: initialText,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(9),
              ],
              textAlign: TextAlign.end,
              style: AppTextStyles.bodyMedium,
              onChanged: onChanged,
              decoration: InputDecoration(
                isDense: true,
                hintText: '0',
                suffixText: splitType == SplitType.percent ? '%' : 'RWF',
                suffixStyle: AppTextStyles.bodySmall,
                enabledBorder: _border(AppColors.edward),
                focusedBorder: _border(AppColors.sherwoodGreen),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: color),
  );
}
