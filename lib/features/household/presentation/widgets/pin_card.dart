// Stylized PIN display card with copy/share buttons

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:changa_app/core/theme/app_colors.dart';
import 'package:changa_app/core/theme/app_spacing.dart';
import 'package:changa_app/core/widgets/app_snackbar.dart';

class PinCard extends StatelessWidget {
  final String pin;
  final VoidCallback? onCopyPin;

  const PinCard({super.key, this.pin = '', this.onCopyPin});

  static final RegExp _validPinRegex = RegExp(r'^\d{6}$');

  bool get hasValidPin => _validPinRegex.hasMatch(pin.trim());

  /// Formats `"482916"` into `"482 916"` for share messages.
  static String formatPinWithSpace(String rawPin) {
    final digits = rawPin.trim();
    if (digits.length == 6) {
      return '${digits.substring(0, 3)} ${digits.substring(3)}';
    }
    return digits;
  }

  /// Formats `"482916"` into `"4 8 2   9 1 6"` for the visual display card.
  static String formatPinForDisplay(String rawPin) {
    final digits = rawPin.trim();
    if (_validPinRegex.hasMatch(digits)) {
      final left = digits.substring(0, 3).split('').join(' ');
      final right = digits.substring(3).split('').join(' ');
      return '$left   $right';
    }
    return '— — —   — — —';
  }

  Future<void> _handleCopy(BuildContext context) async {
    if (!hasValidPin) return;
    if (onCopyPin != null) {
      onCopyPin!();
      return;
    }
    await Clipboard.setData(ClipboardData(text: pin.trim()));
    if (context.mounted) {
      AppSnackbar.success(context, 'PIN copied to clipboard!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = hasValidPin;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'HOUSEHOLD PIN',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: AppColors.edward,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              formatPinForDisplay(pin),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: enabled ? AppColors.sherwoodGreen : AppColors.edward,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton.icon(
            onPressed: enabled ? () => _handleCopy(context) : null,
            icon: Icon(
              Icons.copy_rounded,
              size: 16,
              color: enabled ? AppColors.leafGreen : AppColors.edward,
            ),
            label: Text(
              'Copy PIN',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: enabled ? AppColors.leafGreen : AppColors.edward,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
