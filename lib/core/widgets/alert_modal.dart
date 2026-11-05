import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'primary_button.dart';

class AlertModal extends StatelessWidget {
  const AlertModal({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.primaryText,
    required this.onPrimaryPressed,
    this.secondaryText,
    this.onSecondaryPressed,
    this.dismissText = 'Dismiss',
    this.onDismiss,
  }) : assert(
         (secondaryText == null) == (onSecondaryPressed == null),
         'Provide both secondaryText and onSecondaryPressed, or neither.',
       );

  final IconData icon;
  final String title;
  final String body;

  final String primaryText;
  final VoidCallback onPrimaryPressed;

  final String? secondaryText;
  final VoidCallback? onSecondaryPressed;

  final String dismissText;
  final VoidCallback? onDismiss;

  void _dismiss(BuildContext context) {
    final callback = onDismiss;

    if (callback != null) {
      callback();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Dialog(
      backgroundColor: scheme.surface,
      insetPadding: const EdgeInsets.all(AppSpacing.xxl),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: 'Close',
                onPressed: () => _dismiss(context),
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                icon: const Icon(Icons.close),
              ),
            ),
            Center(
              child: CircleAvatar(
                radius: 32,
                backgroundColor: scheme.primaryContainer,
                foregroundColor: scheme.onPrimaryContainer,
                child: Icon(icon, size: 32),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Semantics(
              header: true,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            PrimaryButton(
              text: primaryText,
              onPressed: onPrimaryPressed,
              textColor: scheme.onSurface,
            ),
            if (secondaryText != null) ...[
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                onPressed: onSecondaryPressed,
                style: OutlinedButton.styleFrom(
                  foregroundColor: scheme.onSurface,
                  minimumSize: const Size(48, 48),
                ),
                child: Text(secondaryText!, textAlign: TextAlign.center),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => _dismiss(context),
              style: TextButton.styleFrom(
                foregroundColor: scheme.onSurface,
                minimumSize: const Size(48, 48),
              ),
              child: Text(dismissText),
            ),
          ],
        ),
      ),
    );
  }
}
