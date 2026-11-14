//  Actions sheet for member management (transfer, remove)

import 'package:flutter/material.dart';
import 'package:changa_app/core/theme/app_colors.dart';
import 'package:changa_app/core/theme/app_spacing.dart';

class MemberActionsSheet extends StatelessWidget {
  final String memberName;
  final bool isAdmin;
  final VoidCallback? onTransferAdmin;
  final VoidCallback? onRemoveMember;

  const MemberActionsSheet({
    super.key,
    this.memberName = 'Housemate',
    this.isAdmin = true,
    this.onTransferAdmin,
    this.onRemoveMember,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.ginFizz,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxl,
            AppSpacing.md,
            AppSpacing.xxl,
            AppSpacing.xxl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.edward.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                memberName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.sherwoodGreen,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (isAdmin)
                ListTile(
                  key: const Key('action-transfer-admin'),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  leading: const Icon(
                    Icons.admin_panel_settings_outlined,
                    color: AppColors.sherwoodGreen,
                  ),
                  title: const Text(
                    'Transfer admin',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.sherwoodGreen,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    onTransferAdmin?.call();
                  },
                ),
              ListTile(
                key: const Key('action-remove-member'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                leading: const Icon(
                  Icons.person_remove_outlined,
                  color: AppColors.sunglo,
                ),
                title: const Text(
                  'Remove from household',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.sunglo,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  onRemoveMember?.call();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
