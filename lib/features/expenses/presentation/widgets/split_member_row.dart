import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:changa_app/core/theme/app_colors.dart';
import 'package:changa_app/core/theme/app_spacing.dart';
import 'package:changa_app/core/theme/app_text_styles.dart';
import 'package:changa_app/core/utils/currency_formatter.dart';
import 'package:changa_app/core/widgets/member_avatar.dart';
import 'package:changa_app/features/expenses/domain/entities/split_type.dart';
import 'package:changa_app/features/expenses/presentation/cubit/add_expense_state.dart';

class SplitMemberRow extends StatelessWidget {
  const SplitMemberRow({
    super.key,
    required this.participant,
    required this.selected,
    required this.splitType,
    required this.share,
    required this.initialText,
    required this.onToggle,
    required this.onChanged,
    this.enabled = true,
  });

  final ExpenseParticipant participant;
  final bool selected;
  final SplitType splitType;
  final int? share;
  final String initialText;
  final VoidCallback onToggle;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              key: ValueKey('split-with-${participant.uid}'),
              borderRadius: BorderRadius.circular(12),
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    Icon(
                      selected
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      color: selected ? AppColors.leafGreen : AppColors.edward,
                    ),
                    const SizedBox(width: AppSpacing.sm),
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
                  ],
                ),
              ),
            ),
          ),
          if (selected && splitType == SplitType.equal && share != null)
            Text(CurrencyFormatter.format(share!), style: AppTextStyles.label)
          else if (selected && splitType != SplitType.equal)
            SizedBox(
              width: 120,
              child: TextFormField(
                key: ValueKey('share-${participant.uid}-${splitType.name}'),
                initialValue: initialText,
                enabled: enabled,
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
                  filled: true,
                  fillColor: AppColors.white,
                  enabledBorder: _border(AppColors.athsSpecial),
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
