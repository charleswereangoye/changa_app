import 'package:flutter/material.dart';

import '../../../../core/enums/settlement_method.dart';
import '../../../../core/theme/app_spacing.dart';

class PaymentMethodSelector extends StatelessWidget {
  const PaymentMethodSelector({
    super.key,
    required this.selectedMethod,
    required this.onChanged,
    this.enabled = true,
  });

  final SettlementMethod selectedMethod;
  final ValueChanged<SettlementMethod> onChanged;
  final bool enabled;

  static const methods = [
    SettlementMethod.momo,
    SettlementMethod.cash,
    SettlementMethod.bank,
  ];

  static String labelFor(SettlementMethod method) {
    return switch (method) {
      SettlementMethod.momo => 'Mobile Money',
      SettlementMethod.cash => 'Cash',
      SettlementMethod.bank => 'Bank Transfer',
      SettlementMethod.credits => 'Chore credits',
    };
  }

  static IconData _iconFor(SettlementMethod method) {
    return switch (method) {
      SettlementMethod.momo => Icons.phone_android_outlined,
      SettlementMethod.cash => Icons.payments_outlined,
      SettlementMethod.bank => Icons.account_balance_outlined,
      SettlementMethod.credits => Icons.stars_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final method in methods)
          ChoiceChip(
            key: ValueKey(method),
            label: Text(labelFor(method)),
            avatar: Icon(_iconFor(method), size: 18),
            selected: selectedMethod == method,
            materialTapTargetSize: MaterialTapTargetSize.padded,
            visualDensity: VisualDensity.standard,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            onSelected: enabled
                ? (selected) {
                    if (selected) {
                      onChanged(method);
                    }
                  }
                : null,
          ),
      ],
    );
  }
}
