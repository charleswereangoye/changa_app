import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:changa_app/features/notifications/presentation/widgets/notification_permission_button.dart';

void main() {
  const buttonKey = Key('notification-permission-button');

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  Future<void> show(
    WidgetTester tester,
    Future<bool?> Function() requestPermission,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: NotificationPermissionButton(
              requestPermission: requestPermission,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> finish(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    debugDefaultTargetPlatformOverride = null;
  }

  for (final granted in <bool?>[true, false, null]) {
    testWidgets('shows feedback for permission result $granted', (
      tester,
    ) async {
      var requests = 0;

      await show(tester, () async {
        requests++;
        return granted;
      });

      // Building the widget must never request permission automatically.
      expect(requests, 0);

      await tester.tap(find.byKey(buttonKey));
      await tester.pumpAndSettle();

      expect(requests, 1);

      final expectedMessage = granted == true
          ? 'Notification permission granted.'
          : 'Notifications are not enabled. '
                'You can allow them in Android Settings.';

      expect(find.text(expectedMessage), findsOneWidget);

      final button = tester.widget<OutlinedButton>(find.byKey(buttonKey));
      expect(button.onPressed, isNotNull);

      await finish(tester);
    });
  }

  testWidgets('prevents duplicate requests while waiting', (tester) async {
    final result = Completer<bool?>();
    var requests = 0;

    await show(tester, () {
      requests++;
      return result.future;
    });

    await tester.tap(find.byKey(buttonKey));
    await tester.pump();

    expect(find.text('Requesting permission…'), findsOneWidget);

    final button = tester.widget<OutlinedButton>(find.byKey(buttonKey));
    expect(button.onPressed, isNull);

    await tester.tap(find.byKey(buttonKey));
    expect(requests, 1);

    result.complete(true);
    await tester.pumpAndSettle();

    expect(
      tester.widget<OutlinedButton>(find.byKey(buttonKey)).onPressed,
      isNotNull,
    );

    await finish(tester);
  });

  testWidgets('shows an error and allows retry after failure', (tester) async {
    var requests = 0;

    await show(tester, () async {
      requests++;

      if (requests == 1) {
        throw StateError('Permission request failed');
      }

      return true;
    });

    await tester.tap(find.byKey(buttonKey));
    await tester.pumpAndSettle();

    expect(
      find.text('Could not request notification permission. Please try again.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(buttonKey));
    await tester.pumpAndSettle();

    expect(requests, 2);
    expect(find.text('Notification permission granted.'), findsOneWidget);

    await finish(tester);
  });

  testWidgets('safely handles disposal during a permission request', (
    tester,
  ) async {
    final result = Completer<bool?>();

    await show(tester, () => result.future);

    await tester.tap(find.byKey(buttonKey));
    await tester.pump();

    await finish(tester);

    result.complete(true);
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('is hidden on unsupported platforms', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    var requests = 0;

    await show(tester, () async {
      requests++;
      return true;
    });

    expect(find.byKey(buttonKey), findsNothing);
    expect(requests, 0);

    await finish(tester);
  });
}
