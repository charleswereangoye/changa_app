import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:changa_app/core/theme/app_theme.dart';
import 'package:changa_app/features/chores/domain/entities/swap_request.dart';
import 'package:changa_app/features/chores/presentation/widgets/swap_request_banner.dart';

SwapRequest _request(String id, DateTime at, {String? note}) => SwapRequest(
  id: id,
  choreId: 'c-$id',
  fromUid: 'kevin',
  toUid: 'me',
  note: note,
  status: SwapStatus.pending,
  createdAt: at,
);

Widget _wrap(
  List<SwapRequest> requests, {
  Set<String> responding = const {},
  void Function(String id, {required bool accept})? onRespond,
}) => MaterialApp(
  theme: AppTheme.lightTheme,
  home: Scaffold(
    body: SwapRequestBanner(
      requests: requests,
      titleOf: (r) => r.id == 'a' ? 'Dishes' : 'Bins',
      nameOf: (_) => 'Kevin Mugo',
      respondingIds: responding,
      onRespond: onRespond ?? (id, {required accept}) {},
    ),
  ),
);

void main() {
  testWidgets('shows nothing when there are no requests', (tester) async {
    await tester.pumpWidget(_wrap(const []));

    expect(find.text('Accept'), findsNothing);
    expect(find.text('Decline'), findsNothing);
  });

  testWidgets('says who wants to swap which chore, with their note', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap([_request('a', DateTime(2026, 11, 10), note: 'Exam week')]),
    );

    expect(find.text('Kevin wants to swap Dishes with you'), findsOneWidget);
    expect(find.text('“Exam week”'), findsOneWidget);
  });

  testWidgets('accept and decline report the request id', (tester) async {
    final answers = <String>[];
    await tester.pumpWidget(
      _wrap([
        _request('a', DateTime(2026, 11, 10)),
      ], onRespond: (id, {required accept}) => answers.add('$id:$accept')),
    );

    await tester.tap(find.text('Accept'));
    await tester.tap(find.text('Decline'));

    expect(answers, ['a:true', 'a:false']);
  });

  testWidgets('the longest-waiting request comes first', (tester) async {
    await tester.pumpWidget(
      _wrap([
        _request('b', DateTime(2026, 11, 11)),
        _request('a', DateTime(2026, 11, 10)),
      ]),
    );

    expect(find.text('Kevin wants to swap Dishes with you'), findsOneWidget);
    expect(find.text('1 more waiting'), findsOneWidget);
  });

  testWidgets('buttons are disabled while answering', (tester) async {
    await tester.pumpWidget(
      _wrap([_request('a', DateTime(2026, 11, 10))], responding: {'a'}),
    );

    final decline = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
    final accept = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(decline.onPressed, isNull);
    expect(accept.onPressed, isNull);
  });

  testWidgets('fits a short, wide screen without overflowing', (tester) async {
    tester.view.physicalSize = const Size(800, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap([_request('a', DateTime(2026, 11, 10))]));

    expect(tester.takeException(), isNull);
    expect(find.text('Accept'), findsOneWidget);
    expect(find.text('Decline'), findsOneWidget);
  });
}
