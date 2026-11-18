// Owner: A - Person A (Foundation, Authentication, Profile)
// Description: Standard bottom sheet wrapper with handle and header matching Figma

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Reusable modal bottom sheet layout container.
class AppBottomSheet extends StatelessWidget {
  final String? title;
  final Widget child;
  final VoidCallback? onClose;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;

  const AppBottomSheet({
    super.key,
    this.title,
    required this.child,
    this.onClose,
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 24),
    this.backgroundColor,
  });

  /// Helper to show an AppBottomSheet modal.
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    bool isScrollControlled = true,
    Color? backgroundColor,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => AppBottomSheet(
        title: title,
        onClose: () => Navigator.of(sheetContext).pop(),
        backgroundColor: backgroundColor,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = isDark ? const Color(0xFF072B28) : AppColors.white;
    final sheetBg = backgroundColor ?? defaultBg;
    final titleColor = isDark ? AppColors.ginFizz : AppColors.sherwoodGreen;

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.edward.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Optional Title Row
              if (title != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title!,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                    if (onClose != null)
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        color: AppColors.edward,
                        onPressed: onClose,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              child,
            ],
          ),
        ),
      ),
    );
  }
}
