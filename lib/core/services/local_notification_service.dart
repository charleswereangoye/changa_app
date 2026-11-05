import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  LocalNotificationService(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  static const String channelId = 'changa_default';
  static const String channelName = 'Changa notifications';

  Future<void>? _initialization;
  void Function(String payload)? _onTap;

  bool get _supportsNotifications =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Initializes the plugin and channel without requesting permission.
  Future<void> initialize({void Function(String payload)? onTap}) async {
    if (!_supportsNotifications) return;

    if (onTap != null) {
      _onTap = onTap;
    }

    final initialization = _initialization ??= _initializePlugin();

    try {
      await initialization;
    } catch (_) {
      if (identical(_initialization, initialization)) {
        _initialization = null;
      }

      rethrow;
    }
  }

  Future<void> _initializePlugin() async {
    final initialized = await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;

        if (payload != null) {
          _onTap?.call(payload);
        }
      },
    );

    if (initialized != true) {
      throw StateError('Android notifications could not be initialized.');
    }

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (android == null) {
      throw StateError('The Android notification plugin is unavailable.');
    }

    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        channelId,
        channelName,
        description: 'Shared expenses, reminders, and chore updates.',
        importance: Importance.high,
      ),
    );
  }

  /// Call from an appropriate UI permission flow, not on each notification.
  Future<bool?> requestPermission() async {
    if (!_supportsNotifications) return false;

    await initialize();

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    return android?.requestNotificationsPermission();
  }

  /// Returns false if this category is muted or the platform is unsupported.
  ///
  /// A true result means the plugin call completed. Android may still suppress
  /// display because of permission, channel, or system notification settings.
  Future<bool> show({
    required String notificationId,
    required String type,
    required String title,
    required String body,
    required bool notifyNudges,
    required bool notifyChores,
    String? refId,
  }) async {
    if (!_supportsNotifications) return false;

    if (type == 'nudge' && !notifyNudges) {
      return false;
    }

    final isChoreUpdate = type == 'swapRequest' || type == 'swapResponse';

    if (isChoreUpdate && !notifyChores) {
      return false;
    }

    await initialize();

    await _plugin.show(
      id: _numericId(notificationId),
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: 'Shared expenses, reminders, and chore updates.',
          icon: 'ic_notification',
          importance: Importance.high,
          priority: Priority.high,
          autoCancel: true,
          onlyAlertOnce: true,
          visibility: NotificationVisibility.private,
          tag: notificationId,
        ),
      ),
      payload: jsonEncode({
        'notificationId': notificationId,
        'type': type,
        'refId': refId,
      }),
    );

    return true;
  }

  /// Reads the payload when an existing local notification launched the app.
  Future<String?> getLaunchPayload() async {
    if (!_supportsNotifications) return null;

    await initialize();

    final details = await _plugin.getNotificationAppLaunchDetails();

    if (details?.didNotificationLaunchApp != true) {
      return null;
    }

    return details?.notificationResponse?.payload;
  }

  /// Clear displayed notifications when the user signs out.
  Future<void> cancelAll() async {
    if (!_supportsNotifications) return;

    await initialize();
    await _plugin.cancelAll();
  }

  /// Generates a stable positive Android notification ID.
  int _numericId(String value) {
    var hash = 0;

    for (final codeUnit in value.codeUnits) {
      hash = ((hash * 31) + codeUnit) & 0x7fffffff;
    }

    return hash;
  }
}
