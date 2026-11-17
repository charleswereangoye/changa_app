import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:changa_app/core/constants/pref_keys.dart';
import 'package:changa_app/core/enums/settlement_method.dart';
import 'package:changa_app/core/enums/split_type.dart';
import 'package:changa_app/features/profile/domain/services/preferences_store.dart';
import 'package:changa_app/features/profile/presentation/cubit/preferences_cubit.dart';

class MockPreferencesStore extends Mock implements PreferencesStore {}

void main() {
  late MockPreferencesStore store;
  late PreferencesCubit cubit;

  void stubReads({
    String theme = 'system',
    bool nudges = true,
    bool chores = true,
    String method = 'momo',
    String split = 'equal',
  }) {
    when(
      () =>
          store.getString(PrefKeys.themeMode, fallback: any(named: 'fallback')),
    ).thenAnswer((_) async => theme);
    when(
      () => store.getBool(
        PrefKeys.notifyNudges,
        fallback: any(named: 'fallback'),
      ),
    ).thenAnswer((_) async => nudges);
    when(
      () => store.getBool(
        PrefKeys.notifyChores,
        fallback: any(named: 'fallback'),
      ),
    ).thenAnswer((_) async => chores);
    when(
      () => store.getString(
        PrefKeys.defaultSettlementMethod,
        fallback: any(named: 'fallback'),
      ),
    ).thenAnswer((_) async => method);
    when(
      () => store.getString(
        PrefKeys.defaultSplitType,
        fallback: any(named: 'fallback'),
      ),
    ).thenAnswer((_) async => split);
  }

  setUp(() {
    store = MockPreferencesStore();
    when(() => store.setString(any(), any())).thenAnswer((_) async {});
    when(() => store.setBool(any(), any())).thenAnswer((_) async {});
    cubit = PreferencesCubit(store);
  });

  tearDown(() => cubit.close());

  group('load', () {
    test('starts with sensible defaults, not yet loaded', () {
      expect(cubit.state.isLoaded, isFalse);
      expect(cubit.state.themeMode, ThemeMode.system);
      expect(cubit.state.defaultSettlementMethod, SettlementMethod.momo);
      expect(cubit.state.defaultSplitType, SplitType.equal);
    });

    test('reads the saved values', () async {
      stubReads(
        theme: 'dark',
        nudges: false,
        chores: false,
        method: 'cash',
        split: 'byAmount',
      );

      await cubit.load();

      expect(cubit.state.isLoaded, isTrue);
      expect(cubit.state.themeMode, ThemeMode.dark);
      expect(cubit.state.notifyNudges, isFalse);
      expect(cubit.state.notifyChores, isFalse);
      expect(cubit.state.defaultSettlementMethod, SettlementMethod.cash);
      expect(cubit.state.defaultSplitType, SplitType.byAmount);
    });

    test('values it no longer recognises fall back', () async {
      stubReads(theme: 'neon', method: 'carrier-pigeon', split: 'random');

      await cubit.load();

      expect(cubit.state.themeMode, ThemeMode.system);
      expect(cubit.state.defaultSettlementMethod, SettlementMethod.momo);
      expect(cubit.state.defaultSplitType, SplitType.equal);
    });

    test('credits can never be the saved default', () async {
      stubReads(method: 'credits');

      await cubit.load();

      expect(cubit.state.defaultSettlementMethod, SettlementMethod.momo);
    });
  });

  group('changing a setting', () {
    test('updates the screen and saves it', () async {
      await cubit.setThemeMode(ThemeMode.dark);
      await cubit.setNotifyNudges(false);
      await cubit.setNotifyChores(false);
      await cubit.setDefaultSettlementMethod(SettlementMethod.bank);
      await cubit.setDefaultSplitType(SplitType.byPercentage);

      expect(cubit.state.themeMode, ThemeMode.dark);
      expect(cubit.state.notifyNudges, isFalse);
      expect(cubit.state.notifyChores, isFalse);
      expect(cubit.state.defaultSettlementMethod, SettlementMethod.bank);
      expect(cubit.state.defaultSplitType, SplitType.byPercentage);
      verify(() => store.setString(PrefKeys.themeMode, 'dark')).called(1);
      verify(() => store.setBool(PrefKeys.notifyNudges, false)).called(1);
      verify(() => store.setBool(PrefKeys.notifyChores, false)).called(1);
      verify(() => store.setString(PrefKeys.defaultSettlementMethod, 'bank'))
          .called(1);
      verify(() => store.setString(PrefKeys.defaultSplitType, 'byPercentage'))
          .called(1);
      expect(cubit.state.saveError, isNull);
    });

    test('credits is refused as a default method', () async {
      await cubit.setDefaultSettlementMethod(SettlementMethod.credits);

      expect(cubit.state.defaultSettlementMethod, SettlementMethod.momo);
      verifyNever(() => store.setString(any(), any()));
    });

    test('a failed save puts the old value back and says so', () async {
      when(() => store.setBool(any(), any()))
          .thenThrow(StateError('The preference could not be saved.'));

      await cubit.setNotifyNudges(false);

      expect(cubit.state.notifyNudges, isTrue);
      expect(cubit.state.saveError, isNotNull);
    });

    test('a failed theme save goes back to the old theme', () async {
      when(() => store.setString(any(), any()))
          .thenThrow(StateError('The preference could not be saved.'));

      await cubit.setThemeMode(ThemeMode.dark);

      expect(cubit.state.themeMode, ThemeMode.system);
      expect(cubit.state.saveError, isNotNull);
    });

    test('the error can be cleared once shown', () async {
      when(() => store.setBool(any(), any())).thenThrow(StateError('nope'));
      await cubit.setNotifyChores(false);

      cubit.clearSaveError();

      expect(cubit.state.saveError, isNull);
    });

    test('the next successful change clears an old error', () async {
      when(() => store.setBool(any(), any())).thenThrow(StateError('nope'));
      await cubit.setNotifyChores(false);
      when(() => store.setBool(any(), any())).thenAnswer((_) async {});

      await cubit.setNotifyChores(false);

      expect(cubit.state.saveError, isNull);
      expect(cubit.state.notifyChores, isFalse);
    });
  });
}
