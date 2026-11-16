import 'package:flutter/material.dart';

import 'package:changa_app/core/theme/app_colors.dart';
import 'package:changa_app/core/theme/app_text_styles.dart';
import 'package:changa_app/features/expenses/domain/entities/split_type.dart';

class SplitTypeSelector extends StatelessWidget {
  const SplitTypeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final SplitType selected;
  final ValueChanged<SplitType> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<SplitType>(
      segments: const [
        ButtonSegment(value: SplitType.equal, label: Text('Equal')),
        ButtonSegment(value: SplitType.percent, label: Text('Percent')),
        ButtonSegment(value: SplitType.exact, label: Text('Exact')),
      ],
      selected: {selected},
      showSelectedIcon: false,
      onSelectionChanged: (values) => onChanged(values.first),
      style: SegmentedButton.styleFrom(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.sherwoodGreen,
        selectedBackgroundColor: AppColors.lightGreen.withValues(alpha: 0.5),
        selectedForegroundColor: AppColors.sherwoodGreen,
        side: const BorderSide(color: AppColors.athsSpecial),
        textStyle: AppTextStyles.label,
      ),
    );
  }
}
