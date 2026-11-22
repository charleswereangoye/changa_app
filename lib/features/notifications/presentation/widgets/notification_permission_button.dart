import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:changa_app/core/widgets/app_snackbar.dart';
import 'package:changa_app/features/notifications/presentation/cubit/notification_permission_cubit.dart';

class NotificationPermissionButton extends StatelessWidget {
  const NotificationPermissionButton({
    super.key,
    required this.requestPermission,
  });

  final Future<bool?> Function() requestPermission;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return const SizedBox.shrink();
    }

    return BlocProvider(
      create: (_) => NotificationPermissionCubit(requestPermission),
      child:
          BlocConsumer<
            NotificationPermissionCubit,
            NotificationPermissionStatus
          >(
            listener: (context, status) {
              switch (status) {
                case NotificationPermissionStatus.granted:
                  AppSnackbar.success(
                    context,
                    'Notification permission granted.',
                  );
                  break;

                case NotificationPermissionStatus.denied:
                  AppSnackbar.info(
                    context,
                    'Notifications are not enabled. '
                    'You can allow them in Android Settings.',
                  );
                  break;

                case NotificationPermissionStatus.failure:
                  AppSnackbar.error(
                    context,
                    'Could not request notification permission. Please try again.',
                  );
                  break;

                case NotificationPermissionStatus.initial:
                case NotificationPermissionStatus.requesting:
                  break;
              }
            },
            builder: (context, status) {
              final requesting =
                  status == NotificationPermissionStatus.requesting;

              return OutlinedButton.icon(
                key: const Key('notification-permission-button'),
                onPressed: requesting
                    ? null
                    : () =>
                          context.read<NotificationPermissionCubit>().request(),
                icon: const Icon(Icons.notifications_outlined),
                label: Text(
                  requesting
                      ? 'Requesting permission…'
                      : 'Allow Android notifications',
                ),
              );
            },
          ),
    );
  }
}
