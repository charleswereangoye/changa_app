import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:changa_app/core/theme/app_colors.dart';
import 'package:changa_app/core/theme/app_theme.dart';
import 'package:changa_app/core/widgets/app_bottom_navigation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final loader = FontLoader('Poppins')
      ..addFont(rootBundle.load('assets/fonts/Poppins-Medium.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Poppins-SemiBold.ttf'));

    await loader.load();
  });

  Future<void> show(
    WidgetTester tester, {
    required Size size,
    required double textScale,
    required ValueChanged<int> onTabSelected,
    required VoidCallback onAddExpense,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          body: const SizedBox.expand(key: Key('page-body')),
          bottomNavigationBar: AppBottomNavigation(
            currentIndex: 2,
            onTabSelected: onTabSelected,
            onAddExpense: onAddExpense,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  Finder navigationScrollable() {
    return find.descendant(
      of: find.byKey(const Key('bottom-navigation-scroll')),
      matching: find.byType(Scrollable),
    );
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pump();
  }

  testWidgets('normal text shows all tabs and reports each action', (
    tester,
  ) async {
    final selected = <int>[];
    var addTaps = 0;

    await show(
      tester,
      size: const Size(430, 932),
      textScale: 1,
      onTabSelected: selected.add,
      onAddExpense: () => addTaps++,
    );

    for (final label in ['Home', 'Chores', 'Activity', 'Profile']) {
      expect(find.text(label), findsOneWidget);
    }

    expect(
      tester.widget<Text>(find.text('Activity')).style?.color,
      AppColors.lightGreen,
    );

    final scrollable = tester.state<ScrollableState>(navigationScrollable());
    expect(scrollable.position.maxScrollExtent, closeTo(0, 0.01));

    for (var index = 0; index < 4; index++) {
      await tapVisible(tester, find.byKey(ValueKey('bottom-tab-$index')));
    }

    await tapVisible(tester, find.byKey(const Key('bottom-add-expense')));

    expect(selected, [0, 1, 2, 3]);
    expect(addTaps, 1);
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(320, 640), const Size(640, 320)]) {
    testWidgets(
      'large-text navigation remains usable at ${size.width}x${size.height}',
      (tester) async {
        final selected = <int>[];
        var addTaps = 0;

        await show(
          tester,
          size: size,
          textScale: 4,
          onTabSelected: selected.add,
          onAddExpense: () => addTaps++,
        );

        final scrollable = tester.state<ScrollableState>(
          navigationScrollable(),
        );

        expect(scrollable.position.maxScrollExtent, greaterThan(0));
        expect(
          tester.getSize(find.byKey(const Key('page-body'))).height,
          greaterThan(0),
        );
        expect(tester.takeException(), isNull);

        for (var index = 0; index < 4; index++) {
          final tab = find.byKey(ValueKey('bottom-tab-$index'));

          await tester.ensureVisible(tab);
          await tester.pumpAndSettle();

          final size = tester.getSize(tab);
          expect(size.width, greaterThanOrEqualTo(48));
          expect(size.height, greaterThanOrEqualTo(48));

          await tester.tap(tab);
          await tester.pump();
          expect(tester.takeException(), isNull);
        }

        await tapVisible(tester, find.byKey(const Key('bottom-add-expense')));

        expect(selected, [0, 1, 2, 3]);
        expect(addTaps, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
