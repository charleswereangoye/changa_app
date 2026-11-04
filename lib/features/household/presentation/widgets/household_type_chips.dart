// Household type selection chips (Apartment, Dorm, House)

import 'package:flutter/material.dart';
import 'package:changa_app/core/theme/app_colors.dart';
import 'package:changa_app/core/theme/app_spacing.dart';
import 'package:changa_app/features/household/domain/entities/household.dart';

class HouseholdTypeChips extends StatelessWidget {
  final HouseholdType selectedType;
  final ValueChanged<HouseholdType>? onSelected;
  final bool enabled;

  const HouseholdTypeChips({
    super.key,
    this.selectedType = HouseholdType.apartment,
    this.onSelected,
    this.enabled = true,
  });

  static String labelFor(HouseholdType type) {
    return switch (type) {
      HouseholdType.apartment => 'Apartment',
      HouseholdType.dorm => 'Dorm',
      HouseholdType.house => 'House',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < HouseholdType.values.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _TypeChipItem(
              label: labelFor(HouseholdType.values[i]),
              isSelected: selectedType == HouseholdType.values[i],
              onTap: enabled && onSelected != null
                  ? () => onSelected!(HouseholdType.values[i])
                  : null,
            ),
          ),
        ],
      ],
    );
  }
}

class _TypeChipItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const _TypeChipItem({
    required this.label,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: Material(
        color: isSelected ? AppColors.sherwoodGreen : AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide(
            color: isSelected
                ? AppColors.sherwoodGreen
                : AppColors.sherwoodGreen.withValues(alpha: 0.1),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 44,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected
                          ? AppColors.white
                          : AppColors.sherwoodGreen,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
