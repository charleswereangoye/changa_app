import 'dart:convert';

/// Navigation information carried by an Android local notification.
class NotificationTapTarget {
  const NotificationTapTarget({
    required this.notificationId,
    required this.type,
    required this.recipientUid,
    required this.actorUid,
    required this.householdId,
    this.refId,
  });

  final String notificationId;
  final String type;
  final String recipientUid;
  final String actorUid;
  final String householdId;
  final String? refId;

  static const _supportedTypes = {
    'newExpense',
    'nudge',
    'settled',
    'swapRequest',
    'swapResponse',
  };

  bool matchesSession({required String uid, required String householdId}) {
    return recipientUid == uid && this.householdId == householdId;
  }

  static NotificationTapTarget? tryParse(String payload) {
    final Object? decoded;

    try {
      decoded = jsonDecode(payload);
    } on FormatException {
      return null;
    }

    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    final Map<String, dynamic> data = decoded;

    String? requiredString(String key) {
      final value = data[key];

      if (value is! String || value.trim().isEmpty) {
        return null;
      }

      return value;
    }

    final notificationId = requiredString('notificationId');
    final type = requiredString('type');
    final recipientUid = requiredString('recipientUid');
    final actorUid = requiredString('actorUid');
    final householdId = requiredString('householdId');
    final refId = data['refId'];

    if (notificationId == null ||
        type == null ||
        !_supportedTypes.contains(type) ||
        recipientUid == null ||
        actorUid == null ||
        householdId == null ||
        (refId != null && refId is! String)) {
      return null;
    }

    return NotificationTapTarget(
      notificationId: notificationId,
      type: type,
      recipientUid: recipientUid,
      actorUid: actorUid,
      householdId: householdId,
      refId: refId as String?,
    );
  }
}
