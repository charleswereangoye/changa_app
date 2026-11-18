// Owner: A - Person A (Foundation, Authentication, Profile)
// Description: Profile header widget with avatar, user info and stats row matching Figma

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/member_avatar.dart';
import '../../../auth/domain/entities/app_user.dart';

/// Header displayed at the top of the Profile screen showing identity and household stats.
class ProfileHeader extends StatelessWidget {
  final AppUser user;
  final String? householdName;
  final DateTime? joinedAt;
  final int? harmonyScore;
  final int credits;
  final int choresDone;

  const ProfileHeader({
    super.key,
    required this.user,
    this.householdName,
    this.joinedAt,
    this.harmonyScore,
    this.credits = 0,
    this.choresDone = 0,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveDate = joinedAt ?? user.createdAt;
    final memberSince = DateFormat('MMM yyyy').format(effectiveDate);
    final householdSubtitle =
        (householdName != null && householdName!.isNotEmpty)
        ? '$householdName · Member since $memberSince'
        : 'Member since $memberSince';

    return Column(
      children: [
        // Avatar + Name + Subtitle
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            children: [
              // 88x88 Avatar with white border and subtle shadow
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: MemberAvatar(
                  uid: user.uid,
                  name: user.fullName,
                  radius: 42,
                ),
              ),
              const SizedBox(height: 14),

              // Full Name
              Text(
                user.fullName.isEmpty ? 'Changa Member' : user.fullName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.sherwoodGreen,
                ),
              ),
              const SizedBox(height: 4),

              // Subtitle
              Text(
                householdSubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.edward,
                ),
              ),
            ],
          ),
        ),

        // Stats Row (Harmony, Credits, Chores Done)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: _StatCard(
                  key: const Key('profile-stat-harmony'),
                  value: harmonyScore != null ? '$harmonyScore' : '—',
                  label: 'Harmony',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  key: const Key('profile-stat-credits'),
                  value: '$credits',
                  label: 'Credits (pts)',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  key: const Key('profile-stat-chores'),
                  value: '$choresDone',
                  label: 'Chores Done',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;

  const _StatCard({super.key, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.sherwoodGreen,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: AppColors.edward,
            ),
          ),
        ],
      ),
    );
  }
}
