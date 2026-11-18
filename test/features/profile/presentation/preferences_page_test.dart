import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:changa_app/core/constants/pref_keys.dart';
import 'package:changa_app/core/theme/app_theme.dart';
import 'package:changa_app/features/profile/domain/services/preferences_store.dart';
import 'package:changa_app/features/profile/presentation/cubit/preferences_cubit.dart';
import 'package:changa_app/features/profile/presentation/pages/preferences_page.dart';

class MockPreferencesStore extends Mock implements PreferencesStore {}

void main() {
  late MockPreferencesStore store;
  late PreferencesCubit cubit;

  setUp(() async {
    store = MockPreferencesStore();
    when(() => store.getString(any(), fallback: any(named: 'fallback')))
        .thenAnswer((i) async => i.namedArguments[#fallback] as String);
    when(() => store.getBool(any(), fallback: any(named: 'fallback')))
        .thenAnswer((i) async => i.namedArguments[#fallback] as bool);
    when(() => store.setString(any(), any())).thenAnswer((_) async {});
    when(() => store.setBool(any(), any())).thenAnswer((_) async {});
    cubit = PreferencesCubit(store);
  });

  tearDown(() => cubit.close());

  Widget page() => MaterialApp(
    theme: AppTheme.lightTheme,
    home: BlocProvider<PreferencesCubit>.value(
      value: cubit,
      child: const PreferencesPage(),
    ),
  );

  testWidgets('waits for the saved values before showing the options', (
    tester,
  ) async {
    await tester.pumpWidget(page());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await cubit.load();
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Appearance'), findsNothing);
    expect(find.text('Default payment method'), findsOneWidget);
  });

  testWidgets('credits is not offered as a default payment method', (
    tester,
  ) async {
    await cubit.load();
    await tester.pumpWidget(page());

    expect(find.text('Mobile Money'), findsOneWidget);
    expect(find.text('Cash'), findsOneWidget);
    expect(find.text('Bank'), findsOneWidget);
    expect(find.textContaining('redit'), findsNothing);
  });

  testWidgets('switching a toggle saves it', (tester) async {
    await cubit.load();
    await tester.pumpWidget(page());

    await tester.tap(find.byKey(const Key('notify-chores-switch')));
    await tester.pump();

    expect(cubit.state.notifyChores, isFalse);
    verify(() => store.setBool(PrefKeys.notifyChores, false)).called(1);
  });

  testWidgets('picking a split saves it', (tester) async {
    await cubit.load();
    await tester.pumpWidget(page());

    await tester.tap(find.byKey(const Key('split-byAmount')));
    await tester.pump();

    verify(() => store.setString(PrefKeys.defaultSplitType, 'byAmount'))
        .called(1);
  });

  testWidgets('a failed save tells the user', (tester) async {
    when(() => store.setBool(any(), any())).thenThrow(StateError('nope'));
    await cubit.load();
    await tester.pumpWidget(page());

    await tester.tap(find.byKey(const Key('notify-nudges-switch')));
    await tester.pump();
    await tester.pump();

    expect(
      find.text('Couldn’t save that setting. Please try again.'),
      findsOneWidget,
    );
    expect(cubit.state.notifyNudges, isTrue);
  });
}
