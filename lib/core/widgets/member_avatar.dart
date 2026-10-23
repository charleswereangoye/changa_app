import 'package:flutter/material.dart';
import 'package:changa_app/core/theme/app_colors.dart';

class MemberAvatar extends StatelessWidget {
  final String? uid;
  final String? name;
  final double radius;
  final bool isSelected;

  const MemberAvatar({
    super.key,
    required this.uid,
    required this.name,
    this.radius = 20.0,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final isFormer = name == null || name == 'Former member';
    final bgColor = isFormer ? Colors.grey.shade400 : _getAvatarColor(uid);
    final initials = _getInitials(name);

    Widget avatar = CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      child: Text(
        initials,
        style: TextStyle(
          color: AppColors.sherwoodGreen,
          fontSize: radius * 0.8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    if (isSelected) {
      avatar = Container(
        padding: const EdgeInsets.all(2.0),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
            width: 2.0,
          ),
        ),
        child: avatar,
      );
    }

    return avatar;
  }

  /// Extracts up to 2 initials from the user's name.
  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty || name == 'Former member') {
      return '?';
    }

    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }

    return parts[0].length > 1
        ? parts[0].substring(0, 2).toUpperCase()
        : parts[0][0].toUpperCase();
  }

  /// Generates a stable color based on a hash of the UID using the Figma palette.
  Color _getAvatarColor(String? uid) {
    if (uid == null || uid.isEmpty) return Colors.grey.shade400;

    int hash = 0;
    for (var i = 0; i < uid.length; i++) {
      hash = uid.codeUnitAt(i) + ((hash << 5) - hash);
    }

    const colors = [
      AppColors.opal,
      AppColors.goldSand,
      AppColors.pewter,
      AppColors.edward,
      AppColors.leafGreen,
      AppColors.sunglo,
    ];

    return colors[hash.abs() % colors.length];
  }
}
