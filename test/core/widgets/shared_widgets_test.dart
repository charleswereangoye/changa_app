import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:changa_app/core/theme/app_theme.dart';
import 'package:changa_app/core/widgets/app_bottom_sheet.dart';
import 'package:changa_app/core/widgets/confirm_dialog.dart';
import 'package:changa_app/core/widgets/empty_state.dart';
import 'package:changa_app/core/widgets/error_view.dart';
import 'package:changa_app/core/widgets/loading_view.dart';
import 'package:changa_app/core/widgets/pill_tab_bar.dart';
import 'package:changa_app/core/widgets/secondary_button.dart';
import 'package:changa_app/core/widgets/section_header.dart';
import 'package:changa_app/features/auth/presentation/widgets/google_sign_in_button.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('ConfirmDialog', () {
    testWidgets('renders title, message, cancel and confirm buttons', (
      tester,
    ) async {
      var confirmed = false;
      var cancelled = false;

      await tester.pumpWidget(
        wrap(
          ConfirmDialog(
            title: 'Delete Item?',
            message: 'This cannot be undone.',
            confirmLabel: 'Delete',
            cancelLabel: 'Keep',
            isDestructive: true,
            onConfirm: () => confirmed = true,
            onCancel: () => cancelled = true,
          ),
        ),
      );

      expect(find.text('Delete Item?'), findsOneWidget);
      expect(find.text('This cannot be undone.'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Keep'), findsOneWidget);

      await tester.tap(find.text('Delete'));
      expect(confirmed, isTrue);

      await tester.tap(find.text('Keep'));
      expect(cancelled, isTrue);
    });
  });

  group('SecondaryButton', () {
    testWidgets('renders label and responds to tap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        wrap(SecondaryButton(label: 'Cancel', onPressed: () => tapped = true)),
      );

      expect(find.text('Cancel'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      expect(tapped, isTrue);
    });

    testWidgets('renders spinner when isLoading is true', (tester) async {
      await tester.pumpWidget(
        wrap(
          SecondaryButton(label: 'Loading', isLoading: true, onPressed: () {}),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('LoadingView', () {
    testWidgets('renders spinner and optional message', (tester) async {
      await tester.pumpWidget(
        wrap(const LoadingView(message: 'Loading household...')),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading household...'), findsOneWidget);
    });
  });

  group('ErrorView', () {
    testWidgets('renders error message and retry button', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        wrap(
          ErrorView(
            message: 'Network connection failed',
            onRetry: () => retried = true,
          ),
        ),
      );

      expect(find.text('Network connection failed'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      await tester.tap(find.text('Try Again'));
      expect(retried, isTrue);
    });
  });

  group('EmptyState', () {
    testWidgets('renders title, description and call-to-action button', (
      tester,
    ) async {
      var actionTapped = false;
      await tester.pumpWidget(
        wrap(
          EmptyState(
            title: 'No Chores Yet',
            description: 'Create your first household chore.',
            icon: Icons.checklist_rounded,
            actionLabel: 'Add Chore',
            onAction: () => actionTapped = true,
          ),
        ),
      );

      expect(find.text('No Chores Yet'), findsOneWidget);
      expect(find.text('Create your first household chore.'), findsOneWidget);
      expect(find.text('Add Chore'), findsOneWidget);

      await tester.tap(find.text('Add Chore'));
      expect(actionTapped, isTrue);
    });
  });

  group('SectionHeader', () {
    testWidgets('renders title and optional action', (tester) async {
      var actionCalled = false;
      await tester.pumpWidget(
        wrap(
          SectionHeader(
            title: 'Recent Activity',
            actionLabel: 'See All',
            onAction: () => actionCalled = true,
          ),
        ),
      );

      expect(find.text('RECENT ACTIVITY'), findsOneWidget);
      expect(find.text('See All'), findsOneWidget);

      await tester.tap(find.text('See All'));
      expect(actionCalled, isTrue);
    });
  });

  group('PillTabBar', () {
    testWidgets('renders tab options and calls back on selection', (
      tester,
    ) async {
      var selected = 0;
      await tester.pumpWidget(
        wrap(
          PillTabBar(
            tabs: const ['Mon 14', 'Tue 15', 'Wed 16'],
            selectedIndex: selected,
            onTabSelected: (index) => selected = index,
          ),
        ),
      );

      expect(find.text('Mon 14'), findsOneWidget);
      expect(find.text('Tue 15'), findsOneWidget);
      expect(find.text('Wed 16'), findsOneWidget);

      await tester.tap(find.text('Tue 15'));
      expect(selected, equals(1));
    });
  });

  group('AppBottomSheet', () {
    testWidgets('renders drag handle, title and content', (tester) async {
      await tester.pumpWidget(
        wrap(
          const AppBottomSheet(
            title: 'Expense Options',
            child: Text('Sheet Content'),
          ),
        ),
      );

      expect(find.text('Expense Options'), findsOneWidget);
      expect(find.text('Sheet Content'), findsOneWidget);
    });
  });

  group('GoogleSignInButton', () {
    testWidgets('renders full-width Google button with label', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        wrap(
          GoogleSignInButton(
            label: 'Continue with Google',
            onPressed: () => tapped = true,
          ),
        ),
      );

      expect(find.text('Continue with Google'), findsOneWidget);
      await tester.tap(find.text('Continue with Google'));
      expect(tapped, isTrue);
    });
  });
}
