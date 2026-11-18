import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:changa_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:changa_app/features/household/presentation/cubit/household_cubit.dart';
import 'package:changa_app/features/notifications/presentation/cubit/notifications_cubit.dart';

/// Keeps notification subscriptions aligned with the current session.
///
/// Requires AuthCubit, HouseholdCubit, and NotificationsCubit above it.
class NotificationSessionListener extends StatefulWidget {
  const NotificationSessionListener({super.key, required this.child});

  final Widget child;

  @override
  State<NotificationSessionListener> createState() =>
      _NotificationSessionListenerState();
}

class _NotificationSessionListenerState
    extends State<NotificationSessionListener> {
  @override
  void initState() {
    super.initState();

    // Also handle a session that was already loaded before this widget mounted.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _syncSession();
      }
    });
  }

  void _syncSession() {
    if (!mounted) return;

    final auth = context.read<AuthCubit>().state;
    final household = context.read<HouseholdCubit>().state;

    final uid = auth is Authenticated ? auth.user.uid : null;

    // During account switching, an old household must never be used for
    // the newly authenticated account.
    final householdId =
        uid != null &&
            household is HouseholdStateLoaded &&
            household.currentMember?.uid == uid
        ? household.household.id
        : null;

    unawaited(
      context.read<NotificationsCubit>().start(
        uid: uid,
        householdId: householdId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthCubit, AuthState>(
          listener: (context, state) => _syncSession(),
        ),
        BlocListener<HouseholdCubit, HouseholdState>(
          listener: (context, state) => _syncSession(),
        ),
      ],
      child: widget.child,
    );
  }
}
