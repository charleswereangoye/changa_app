import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:changa_app/core/services/local_notification_service.dart';
import 'package:changa_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:changa_app/features/household/presentation/cubit/household_cubit.dart';
import 'package:changa_app/features/notifications/domain/entities/app_notification.dart';
import 'package:changa_app/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:changa_app/features/notifications/presentation/cubit/notifications_state.dart';
import 'package:changa_app/features/notifications/presentation/logic/local_notification_dispatcher.dart';
import 'package:changa_app/features/notifications/presentation/logic/notification_tap_target.dart';
import 'package:changa_app/features/profile/presentation/cubit/preferences_cubit.dart';
import 'package:changa_app/features/profile/presentation/cubit/preferences_state.dart';

/// Connects local Android notifications to the active application session.
class LocalNotificationListener extends StatefulWidget {
  const LocalNotificationListener({
    super.key,
    required this.service,
    required this.onOpen,
    required this.child,
  });

  final LocalNotificationService service;
  final ValueChanged<AppNotification> onOpen;
  final Widget child;

  @override
  State<LocalNotificationListener> createState() =>
      _LocalNotificationListenerState();
}

class _LocalNotificationListenerState extends State<LocalNotificationListener>
    with WidgetsBindingObserver {
  late final LocalNotificationDispatcher _dispatcher;
  AppLifecycleState? _lifecycle;
  NotificationTapTarget? _pendingTap;

  @override
  void initState() {
    super.initState();

    _lifecycle = WidgetsBinding.instance.lifecycleState;
    WidgetsBinding.instance.addObserver(this);

    _dispatcher = LocalNotificationDispatcher(
      widget.service,
      onError: (error, stackTrace) {
        debugPrint('Local notification delivery failed: $error');
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _sync();
      unawaited(_initialize());
    });
  }

  Future<void> _initialize() async {
    try {
      await widget.service.initialize(onTap: _onTap);

      final payload = await widget.service.getLaunchPayload();
      if (!mounted || payload == null) return;

      _onTap(payload);
    } catch (error) {
      debugPrint('Local notification initialization failed: $error');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycle = state;
    _sync();
  }

  (String, String)? get _session {
    final auth = context.read<AuthCubit>().state;
    final household = context.read<HouseholdCubit>().state;

    if (auth is! Authenticated ||
        household is! HouseholdStateLoaded ||
        household.currentMember?.uid != auth.user.uid) {
      return null;
    }

    return (auth.user.uid, household.household.id);
  }

  void _sync() {
    if (!mounted) return;

    final session = _session;

    _dispatcher.updateSession(uid: session?.$1, householdId: session?.$2);

    if (context.read<AuthCubit>().state is Unauthenticated) {
      _pendingTap = null;
    }

    if (session == null) return;

    final preferences = context.read<PreferencesCubit>().state;
    final notifications = context.read<NotificationsCubit>().state;

    if (!preferences.isLoaded ||
        notifications.status != NotificationsStatus.loaded) {
      return;
    }

    _dispatcher.dispatch(
      pendingAlerts: notifications.pendingAlerts,
      isForeground:
          _lifecycle == null || _lifecycle == AppLifecycleState.resumed,
      notifyNudges: preferences.notifyNudges,
      notifyChores: preferences.notifyChores,
    );

    _tryOpenPendingTap();
  }

  void _onTap(String payload) {
    if (!mounted) return;

    final target = NotificationTapTarget.tryParse(payload);
    if (target == null) return;

    _pendingTap = target;
    _sync();
  }

  void _tryOpenPendingTap() {
    final target = _pendingTap;
    final session = _session;

    if (target == null || session == null) return;

    if (!target.matchesSession(uid: session.$1, householdId: session.$2)) {
      _pendingTap = null;
      return;
    }

    final cubit = context.read<NotificationsCubit>();
    AppNotification? matchingNotification;

    // Use the current recipient's notification data rather than trusting
    // navigation fields supplied by the local payload alone.
    for (final notification in cubit.state.unread) {
      if (notification.id == target.notificationId &&
          notification.recipientUid == session.$1 &&
          notification.actorUid == target.actorUid &&
          notification.type == target.type) {
        matchingNotification = notification;
        break;
      }
    }

    _pendingTap = null;

    if (matchingNotification == null) return;

    cubit.dismissAlert(matchingNotification.id);
    unawaited(cubit.markRead(matchingNotification.id));
    widget.onOpen(matchingNotification);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pendingTap = null;
    _dispatcher.updateSession(uid: null, householdId: null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthCubit, AuthState>(
          listener: (context, state) => _sync(),
        ),
        BlocListener<HouseholdCubit, HouseholdState>(
          listener: (context, state) => _sync(),
        ),
        BlocListener<PreferencesCubit, PreferencesState>(
          listener: (context, state) => _sync(),
        ),
        BlocListener<NotificationsCubit, NotificationsState>(
          listener: (context, state) => _sync(),
        ),
      ],
      child: widget.child,
    );
  }
}
