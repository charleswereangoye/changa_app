import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:changa_app/core/theme/app_theme.dart';
import 'package:changa_app/features/notifications/domain/entities/app_notification.dart';
import 'package:changa_app/features/notifications/presentation/widgets/in_app_banner.dart';

AppNotification _notification(String id) {
  return AppNotification(
    id: id,
    recipientUid: 'me',
    actorUid: 'kevin',
    type: 'nudge',
    title: 'Kevin sent you a nudge',
    body: 'A friendly reminder about the shared WiFi bill.',
    read: false,
    createdAt: DateTime.utc(2026, 11, 18),
  );
}

Future<void> _show(
  WidgetTester tester, {
  String id = 'notification-1',
  VoidCallback? onTap,
  VoidCallback? onDismiss,
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: InAppBanner(
              notification: _notification(id),
              onTap: onTap ?? () {},
              onDismiss: onDismiss ?? () {},
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows the notification title and body', (tester) async {
    await _show(tester);
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Kevin sent you a nudge'), findsOneWidget);
    expect(
      find.text('A friendly reminder about the shared WiFi bill.'),
      findsOneWidget,
    );
    expect(find.byTooltip('Dismiss notification'), findsOneWidget);
  });

  testWidgets('dismisses once after four seconds', (tester) async {
    var dismissals = 0;

    await _show(tester, onDismiss: () => dismissals++);

    await tester.pump(const Duration(milliseconds: 3999));
    expect(dismissals, 0);

    await tester.pump(const Duration(milliseconds: 1));
    expect(dismissals, 1);

    await tester.pump(const Duration(seconds: 5));
    expect(dismissals, 1);
  });

  testWidgets('tapping opens once and cancels automatic dismissal', (
    tester,
  ) async {
    var opens = 0;
    var dismissals = 0;

    await _show(tester, onTap: () => opens++, onDismiss: () => dismissals++);
    await tester.pump(const Duration(milliseconds: 250));

    final banner = find.byKey(const Key('notification-banner-open'));
    await tester.tap(banner);
    await tester.tap(banner);

    expect(opens, 1);
    expect(dismissals, 0);

    await tester.pump(const Duration(seconds: 5));

    expect(opens, 1);
    expect(dismissals, 0);
  });

  testWidgets('closing dismisses once without opening', (tester) async {
    var opens = 0;
    var dismissals = 0;

    await _show(tester, onTap: () => opens++, onDismiss: () => dismissals++);
    await tester.pump(const Duration(milliseconds: 250));

    final close = find.byKey(const Key('notification-banner-dismiss'));
    await tester.tap(close);
    await tester.tap(close);

    await tester.pump(const Duration(seconds: 5));

    expect(opens, 0);
    expect(dismissals, 1);
  });

  testWidgets('removing the banner cancels its timer', (tester) async {
    var dismissals = 0;

    await _show(tester, onDismiss: () => dismissals++);
    await tester.pump(const Duration(seconds: 1));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 5));

    expect(dismissals, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a replacement notification gets its own four seconds', (
    tester,
  ) async {
    var dismissals = 0;

    await _show(tester, onDismiss: () => dismissals++);
    await tester.pump(const Duration(seconds: 3));

    await _show(tester, id: 'notification-2', onDismiss: () => dismissals++);

    await tester.pump(const Duration(seconds: 1));
    expect(dismissals, 0);

    await tester.pump(const Duration(seconds: 3));
    expect(dismissals, 1);
  });

  testWidgets('fits a 320px screen with enlarged text', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _show(tester, textScale: 1.5);
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Kevin sent you a nudge'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final closeSize = tester.getSize(
      find.byKey(const Key('notification-banner-dismiss')),
    );

    expect(closeSize.width, greaterThanOrEqualTo(48));
    expect(closeSize.height, greaterThanOrEqualTo(48));
  });
}
