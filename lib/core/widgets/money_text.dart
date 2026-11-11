// Owner: C - Person C (Expenses, Dashboard, Documentation)
// Description: Formatted monetary text colored by balance status

import 'package:flutter/material.dart';

import 'package:changa_app/core/theme/app_colors.dart';
import 'package:changa_app/core/theme/app_text_styles.dart';
import 'package:changa_app/core/utils/currency_formatter.dart';

/// Shows a whole-RWF amount, e.g. "RWF 24,000".
///
/// With [colored] set, a positive amount (someone owes you) is green, a
/// negative amount (you owe) is coral and zero stays the neutral dark green.
class MoneyText extends StatelessWidget {
  const MoneyText(
    this.amount, {
    super.key,
    this.style,
    this.colored = false,
    this.showPlus = false,
    this.textAlign,
  });

  final int amount;
  final TextStyle? style;
  final bool colored;

  /// Adds a "+" in front of positive amounts.
  final bool showPlus;
  final TextAlign? textAlign;

  static Color colorFor(int amount) {
    if (amount > 0) return AppColors.leafGreen;
    if (amount < 0) return AppColors.sunglo;
    return AppColors.sherwoodGreen;
  }

  String get text {
    final formatted = CurrencyFormatter.format(amount);
    return showPlus && amount > 0 ? '+$formatted' : formatted;
  }

  @override
  Widget build(BuildContext context) {
    final base = style ?? AppTextStyles.bodyLarge;
    return Text(
      text,
      textAlign: textAlign,
      style: colored ? base.copyWith(color: colorFor(amount)) : base,
    );
  }
}
