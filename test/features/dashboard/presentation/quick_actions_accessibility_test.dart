import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:changa_app/core/theme/app_theme.dart';
import 'package:changa_app/features/dashboard/presentation/widgets/quick_actions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final loader = FontLoader('Poppins')
      ..addFont(rootBundle.load('assets/fonts/Poppins-SemiBold.ttf'));

    await loader.load();
  });

  const expenseKey = Key('quick-add-expense');
  const choreKey = Key('quick-add-chore');

  Future<void> show(
    WidgetTester tester, {
    required Size size,
    required double textScale,
    required VoidCallback onExpense,
    required VoidCallback onChore,
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
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: QuickActions(onAddExpense: onExpense, onAddChore: onChore),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  testWidgets('normal text keeps actions beside each other', (tester) async {
    await show(
      tester,
      size: const Size(430, 932),
      textScale: 1,
      onExpense: () {},
      onChore: () {},
    );

    final expense = tester.getRect(find.byKey(expenseKey));
    final chore = tester.getRect(find.byKey(choreKey));

    expect(expense.top, chore.top);
    expect(expense.right, lessThan(chore.left));
    expect(expense.height, greaterThanOrEqualTo(48));
    expect(chore.height, greaterThanOrEqualTo(48));
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(320, 640), const Size(640, 320)]) {
    testWidgets(
      'large text stacks usable actions at ${size.width}x${size.height}',
      (tester) async {
        var expenseTaps = 0;
        var choreTaps = 0;

        await show(
          tester,
          size: size,
          textScale: 4,
          onExpense: () => expenseTaps++,
          onChore: () => choreTaps++,
        );

        final expenseFinder = find.byKey(expenseKey);
        final choreFinder = find.byKey(choreKey);

        final expense = tester.getRect(expenseFinder);
        final chore = tester.getRect(choreFinder);

        expect(chore.top, greaterThanOrEqualTo(expense.bottom));
        expect(expense.height, greaterThanOrEqualTo(48));
        expect(chore.height, greaterThanOrEqualTo(48));
        expect(tester.takeException(), isNull);

        await tester.ensureVisible(expenseFinder);
        await tester.pumpAndSettle();
        await tester.tap(expenseFinder);
        await tester.pump();

        await tester.ensureVisible(choreFinder);
        await tester.pumpAndSettle();
        await tester.tap(choreFinder);
        await tester.pump();

        expect(expenseTaps, 1);
        expect(choreTaps, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
