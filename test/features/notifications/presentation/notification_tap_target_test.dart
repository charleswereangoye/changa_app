import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:changa_app/features/notifications/presentation/logic/notification_tap_target.dart';

Map<String, dynamic> _payload() => {
  'notificationId': 'notice-1',
  'type': 'nudge',
  'recipientUid': 'amara',
  'actorUid': 'jean',
  'householdId': 'home-1',
  'refId': 'expense-1',
};

void main() {
  test('reads all navigation fields', () {
    final target = NotificationTapTarget.tryParse(jsonEncode(_payload()));

    expect(target, isNotNull);
    expect(target!.notificationId, 'notice-1');
    expect(target.type, 'nudge');
    expect(target.recipientUid, 'amara');
    expect(target.actorUid, 'jean');
    expect(target.householdId, 'home-1');
    expect(target.refId, 'expense-1');
  });

  for (final type in [
    'newExpense',
    'nudge',
    'settled',
    'swapRequest',
    'swapResponse',
  ]) {
    test('accepts the supported type $type', () {
      final payload = _payload()..['type'] = type;

      expect(NotificationTapTarget.tryParse(jsonEncode(payload))?.type, type);
    });
  }

  for (final input in ['{broken', 'null', '[]', '"hello"', '42']) {
    test('rejects invalid or non-object JSON: $input', () {
      expect(NotificationTapTarget.tryParse(input), isNull);
    });
  }

  for (final field in [
    'notificationId',
    'type',
    'recipientUid',
    'actorUid',
    'householdId',
  ]) {
    test('rejects missing $field', () {
      final payload = _payload()..remove(field);

      expect(NotificationTapTarget.tryParse(jsonEncode(payload)), isNull);
    });

    test('rejects invalid values for $field', () {
      for (final value in <Object?>[null, '', '   ', 123, true, []]) {
        final payload = _payload()..[field] = value;

        expect(
          NotificationTapTarget.tryParse(jsonEncode(payload)),
          isNull,
          reason: '$field must reject $value',
        );
      }
    });
  }

  test('rejects an unsupported notification type', () {
    final payload = _payload()..['type'] = 'unknown';

    expect(NotificationTapTarget.tryParse(jsonEncode(payload)), isNull);
  });

  test('accepts an absent or null optional reference', () {
    final absent = _payload()..remove('refId');
    final explicitNull = _payload()..['refId'] = null;

    for (final payload in [absent, explicitNull]) {
      final target = NotificationTapTarget.tryParse(jsonEncode(payload));

      expect(target, isNotNull);
      expect(target!.refId, isNull);
    }
  });

  test('rejects a non-string reference', () {
    final payload = _payload()..['refId'] = 123;

    expect(NotificationTapTarget.tryParse(jsonEncode(payload)), isNull);
  });

  test('matches only the intended account and household', () {
    final target = NotificationTapTarget.tryParse(jsonEncode(_payload()))!;

    expect(target.matchesSession(uid: 'amara', householdId: 'home-1'), isTrue);
    expect(target.matchesSession(uid: 'grace', householdId: 'home-1'), isFalse);
    expect(target.matchesSession(uid: 'amara', householdId: 'home-2'), isFalse);
  });
}
