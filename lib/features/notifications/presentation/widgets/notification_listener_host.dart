import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:changa_app/core/widgets/alert_modal.dart';
import 'package:changa_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:changa_app/features/household/presentation/cubit/household_cubit.dart';
import 'package:changa_app/features/notifications/domain/entities/app_notification.dart';
import 'package:changa_app/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:changa_app/features/notifications/presentation/cubit/notifications_state.dart';
import 'package:changa_app/features/profile/presentation/cubit/preferences_cubit.dart';
import 'package:changa_app/features/profile/presentation/cubit/preferences_state.dart';

import 'package:changa_app/features/notifications/presentation/widgets/in_app_banner.dart';
import 'package:changa_app/features/notifications/presentation/widgets/notification_session_listener.dart';

/// Displays one queued notification at a time above the root navigator.
class NotificationListenerHost extends StatefulWidget {
  const NotificationListenerHost({
    super.key,
    required this.child,
    required this.navigatorKey,
    required this.onOpen,
  });

  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;
  final ValueChanged<AppNotification> onOpen;

  @override
  State<NotificationListenerHost> createState() =>
      _NotificationListenerHostState();
}

class _NotificationListenerHostState extends State<NotificationListenerHost> {
  OverlayEntry? _banner;
  DialogRoute<bool>? _dialog;
  AppNotification? _active;
  (String, String)? _session;
  int _generation = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _sync();
      }
    });
  }

  (String, String)? get _currentSession {
    final auth = context.read<AuthCubit>().state;
    final household = context.read<HouseholdCubit>().state;

    if (auth is! Authenticated ||
        household is! HouseholdStateLoaded ||
        household.currentMember?.uid != auth.user.uid) {
      return null;
    }

    return (auth.user.uid, household.household.id);
  }

  bool _enabled(AppNotification notification, PreferencesState preferences) {
    return switch (notification.type) {
      'nudge' => preferences.notifyNudges,
      'swapRequest' || 'swapResponse' => preferences.notifyChores,
      _ => true,
    };
  }

  void _sync() {
    if (!mounted) return;

    final session = _currentSession;

    if (session != _session) {
      _session = session;
      ++_generation;
      _clearPresentation();
    }

    final notifications = context.read<NotificationsCubit>();
    final state = notifications.state;
    final preferences = context.read<PreferencesCubit>().state;
    final active = _active;

    if (active != null &&
        (!state.pendingAlerts.any((item) => item.id == active.id) ||
            !_enabled(active, preferences))) {
      ++_generation;
      _clearPresentation();
    }

    if (session == null ||
        !preferences.isLoaded ||
        state.status != NotificationsStatus.loaded ||
        _active != null) {
      return;
    }

    for (final notification in state.pendingAlerts) {
      if (notification.recipientUid != session.$1 ||
          !_enabled(notification, preferences)) {
        notifications.dismissAlert(notification.id);
        continue;
      }

      _showBanner(notification);
      break;
    }
  }

  void _showBanner(AppNotification notification) {
    final overlay = widget.navigatorKey.currentState?.overlay;
    if (overlay == null) return;

    final generation = _generation;
    _active = notification;

    final entry = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: InAppBanner(
                  key: ValueKey(notification.id),
                  notification: notification,
                  onTap: () => _tap(notification, generation),
                  onDismiss: () => _dismiss(notification, generation),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    _banner = entry;
    overlay.insert(entry);
  }

  bool _isCurrent(AppNotification notification, int generation) {
    return mounted &&
        generation == _generation &&
        _currentSession == _session &&
        _session != null &&
        _active?.id == notification.id;
  }

  void _tap(AppNotification notification, int generation) {
    if (!_isCurrent(notification, generation)) return;

    _removeBanner();

    if (notification.type == 'nudge') {
      unawaited(_showNudge(notification, generation));
    } else {
      _openDetails(notification, generation);
    }
  }

  Future<void> _showNudge(AppNotification notification, int generation) async {
    final navigator = widget.navigatorKey.currentState;
    final overlay = navigator?.overlay;

    if (navigator == null || overlay == null) {
      _dismiss(notification, generation);
      return;
    }

    final route = DialogRoute<bool>(
      context: overlay.context,
      builder: (dialogContext) => AlertModal(
        icon: Icons.send_rounded,
        title: notification.title,
        body: notification.body,
        primaryText: 'View Details',
        onPrimaryPressed: () => Navigator.of(dialogContext).pop(true),
        onDismiss: () => Navigator.of(dialogContext).pop(false),
      ),
    );

    _dialog = route;
    final open = await navigator.push<bool>(route);

    if (!_isCurrent(notification, generation)) return;

    _dialog = null;

    if (open == true) {
      _openDetails(notification, generation);
    } else {
      _dismiss(notification, generation);
    }
  }

  void _openDetails(AppNotification notification, int generation) {
    if (!_isCurrent(notification, generation)) return;

    _removeBanner();
    _active = null;

    final notifications = context.read<NotificationsCubit>();
    notifications.dismissAlert(notification.id);
    unawaited(notifications.markRead(notification.id));

    widget.onOpen(notification);
    _sync();
  }

  void _dismiss(AppNotification notification, int generation) {
    if (!_isCurrent(notification, generation)) return;

    _removeBanner();
    _active = null;

    // Closing an alert keeps the notification unread.
    context.read<NotificationsCubit>().dismissAlert(notification.id);
    _sync();
  }

  void _removeBanner() {
    final banner = _banner;
    _banner = null;

    if (banner != null) {
      banner.remove();
      banner.dispose();
    }
  }

  void _clearPresentation() {
    _removeBanner();
    _active = null;

    final dialog = _dialog;
    _dialog = null;

    // Remove this host's dialog specifically, without popping another route.
    if (dialog != null && dialog.isActive) {
      widget.navigatorKey.currentState?.removeRoute(dialog);
    }
  }

  @override
  void dispose() {
    ++_generation;
    _clearPresentation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationSessionListener(
      child: MultiBlocListener(
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
      ),
    );
  }
}
