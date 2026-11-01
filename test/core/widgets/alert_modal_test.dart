import 'package:changa_app/core/theme/app_theme.dart';
import 'package:changa_app/core/widgets/alert_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _title = 'New nudge from Kevin';

void main() {
  testWidgets('shows the content without an optional secondary action', (
    tester,
  ) async {
    await _openAlert(tester);

    expect(find.text(_title), findsOneWidget);
    expect(
      find.text('A friendly reminder about the WiFi bill.'),
      findsOneWidget,
    );
    expect(find.text('View details'), findsOneWidget);
    expect(find.text('Dismiss'), findsOneWidget);
    expect(find.byIcon(Icons.send_outlined), findsOneWidget);
    expect(find.byType(OutlinedButton), findsNothing);
  });

  testWidgets('primary action invokes its callback without auto-dismissing', (
    tester,
  ) async {
    var calls = 0;

    await _openAlert(
      tester,
      onPrimaryPressed: () {
        calls++;
      },
    );

    await tester.ensureVisible(find.text('View details'));
    await tester.tap(find.text('View details'));
    await tester.pump();

    expect(calls, 1);
    expect(find.text(_title), findsOneWidget);
  });

  testWidgets('optional secondary action invokes its callback', (tester) async {
    var calls = 0;

    await _openAlert(
      tester,
      secondaryText: 'Remind me later',
      onSecondaryPressed: () {
        calls++;
      },
    );

    await tester.ensureVisible(find.text('Remind me later'));
    await tester.tap(find.text('Remind me later'));
    await tester.pump();

    expect(calls, 1);
    expect(find.text(_title), findsOneWidget);
  });

  testWidgets('Dismiss closes the dialog by default', (tester) async {
    await _openAlert(tester);

    await tester.ensureVisible(find.text('Dismiss'));
    await tester.tap(find.text('Dismiss'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertModal), findsNothing);
    expect(find.text('Open alert'), findsOneWidget);
  });

  testWidgets('Close icon closes the dialog by default', (tester) async {
    await _openAlert(tester);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertModal), findsNothing);
  });

  testWidgets('a custom dismiss callback controls dismissal', (tester) async {
    var calls = 0;

    await _openAlert(
      tester,
      onDismiss: () {
        calls++;
      },
    );

    await tester.ensureVisible(find.text('Dismiss'));
    await tester.tap(find.text('Dismiss'));
    await tester.pump();

    expect(calls, 1);
    expect(find.byType(AlertModal), findsOneWidget);
  });

  testWidgets('long content scrolls on a small screen with larger text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;

    addTearDown(tester.view.reset);

    await _openAlert(
      tester,
      textScale: 1.5,
      body: List.filled(
        12,
        'A friendly reminder about your shared household expenses.',
      ).join(' '),
    );

    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text('View details'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text('Dismiss'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dismiss'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(AlertModal), findsNothing);
  });
}

Future<void> _openAlert(
  WidgetTester tester, {
  VoidCallback? onPrimaryPressed,
  String? secondaryText,
  VoidCallback? onSecondaryPressed,
  VoidCallback? onDismiss,
  String body = 'A friendly reminder about the WiFi bill.',
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        );
      },
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return Center(
              child: TextButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (_) => AlertModal(
                      icon: Icons.send_outlined,
                      title: _title,
                      body: body,
                      primaryText: 'View details',
                      onPrimaryPressed: onPrimaryPressed ?? () {},
                      secondaryText: secondaryText,
                      onSecondaryPressed: onSecondaryPressed,
                      onDismiss: onDismiss,
                    ),
                  );
                },
                child: const Text('Open alert'),
              ),
            );
          },
        ),
      ),
    ),
  );

  await tester.tap(find.text('Open alert'));
  await tester.pumpAndSettle();
}
