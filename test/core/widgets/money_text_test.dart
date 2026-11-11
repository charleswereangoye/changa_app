// Owner: C - Person C (Expenses, Dashboard, Documentation)
// Description: Widget tests for MoneyText

import 'package:changa_app/core/theme/app_colors.dart';
import 'package:changa_app/core/widgets/money_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<Text> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
  return tester.widget<Text>(find.byType(Text));
}

void main() {
  testWidgets('formats whole RWF with separators', (tester) async {
    final text = await _pump(tester, const MoneyText(24000));
    expect(text.data, 'RWF 24,000');
  });

  testWidgets('negative amounts keep the minus sign', (tester) async {
    final text = await _pump(tester, const MoneyText(-500));
    expect(text.data, '-RWF 500');
  });

  testWidgets('showPlus adds a plus only to positive amounts', (tester) async {
    final positive = await _pump(tester, const MoneyText(500, showPlus: true));
    expect(positive.data, '+RWF 500');

    final zero = await _pump(tester, const MoneyText(0, showPlus: true));
    expect(zero.data, 'RWF 0');
  });

  testWidgets('colored: green when owed, coral when owing, neutral at zero', (
    tester,
  ) async {
    final owed = await _pump(tester, const MoneyText(500, colored: true));
    expect(owed.style?.color, AppColors.leafGreen);

    final owing = await _pump(tester, const MoneyText(-500, colored: true));
    expect(owing.style?.color, AppColors.sunglo);

    final even = await _pump(tester, const MoneyText(0, colored: true));
    expect(even.style?.color, AppColors.sherwoodGreen);
  });

  testWidgets('not colored by default', (tester) async {
    final text = await _pump(tester, const MoneyText(-500));
    expect(text.style?.color, isNot(AppColors.sunglo));
  });
}
