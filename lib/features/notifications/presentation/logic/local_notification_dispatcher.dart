import 'package:changa_app/core/services/local_notification_service.dart';
import 'package:changa_app/features/notifications/domain/entities/app_notification.dart';

/// Serializes Android notification writes across account changes.
class LocalNotificationDispatcher {
  LocalNotificationDispatcher(this._service, {required this.onError});

  final LocalNotificationService _service;
  final void Function(Object error, StackTrace stackTrace) onError;

  final Set<String> _handledIds = {};
  Future<void> _pending = Future<void>.value();

  (String, String)? _session;
  int _generation = 0;

  /// Useful when waiting for queued delivery or cleanup to finish.
  Future<void> get idle => _pending;

  void updateSession({required String? uid, required String? householdId}) {
    final nextSession =
        uid != null &&
            uid.trim().isNotEmpty &&
            householdId != null &&
            householdId.trim().isNotEmpty
        ? (uid, householdId)
        : null;

    if (nextSession == _session) return;

    _session = nextSession;
    ++_generation;
    _handledIds.clear();

    // Runs after any in-progress show call and before new-session delivery.
    _enqueue(_service.cancelAll);
  }

  void dispatch({
    required List<AppNotification> pendingAlerts,
    required bool isForeground,
    required bool notifyNudges,
    required bool notifyChores,
  }) {
    final session = _session;
    if (session == null) return;

    final generation = _generation;

    for (final notification in pendingAlerts) {
      if (notification.recipientUid != session.$1 ||
          !_handledIds.add(notification.id)) {
        continue;
      }

      // Foreground notifications use the in-app banner.
      // Record them now so backgrounding does not replay them.
      if (isForeground) continue;

      final mutedNudge = notification.type == 'nudge' && !notifyNudges;
      final choreUpdate =
          notification.type == 'swapRequest' ||
          notification.type == 'swapResponse';

      if (mutedNudge || (choreUpdate && !notifyChores)) {
        continue;
      }

      _enqueue(() async {
        // Ignore work queued before an account or household change.
        if (generation != _generation || session != _session) {
          return;
        }

        await _service.show(
          notificationId: notification.id,
          type: notification.type,
          title: notification.title,
          body: notification.body,
          notifyNudges: notifyNudges,
          notifyChores: notifyChores,
          refId: notification.refId,
          recipientUid: notification.recipientUid,
          actorUid: notification.actorUid,
          householdId: session.$2,
        );
      });
    }
  }

  void _enqueue(Future<void> Function() action) {
    _pending = _pending.then((_) async {
      try {
        await action();
      } catch (error, stackTrace) {
        onError(error, stackTrace);
      }
    });
  }
}
