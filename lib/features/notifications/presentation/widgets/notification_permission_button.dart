import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:changa_app/core/widgets/app_snackbar.dart';

class NotificationPermissionButton extends StatefulWidget {
  const NotificationPermissionButton({
    super.key,
    required this.requestPermission,
  });

  final Future<bool?> Function() requestPermission;

  @override
  State<NotificationPermissionButton> createState() =>
      _NotificationPermissionButtonState();
}

class _NotificationPermissionButtonState
    extends State<NotificationPermissionButton> {
  bool _requesting = false;

  Future<void> _request() async {
    if (_requesting) return;

    setState(() => _requesting = true);

    try {
      final granted = await widget.requestPermission();

      if (!mounted) return;

      if (granted == true) {
        AppSnackbar.success(context, 'Notification permission granted.');
      } else {
        AppSnackbar.info(
          context,
          'Notifications are not enabled. '
          'You can allow them in Android Settings.',
        );
      }
    } catch (_) {
      if (!mounted) return;

      AppSnackbar.error(
        context,
        'Could not request notification permission. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _requesting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return const SizedBox.shrink();
    }

    return OutlinedButton.icon(
      key: const Key('notification-permission-button'),
      onPressed: _requesting ? null : _request,
      icon: const Icon(Icons.notifications_outlined),
      label: Text(
        _requesting ? 'Requesting permission…' : 'Allow Android notifications',
      ),
    );
  }
}
