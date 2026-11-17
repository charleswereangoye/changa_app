import 'package:changa_app/core/enums/split_type.dart';
import 'package:changa_app/core/enums/settlement_method.dart';
import 'package:changa_app/core/constants/pref_keys.dart';
import 'package:changa_app/features/profile/domain/services/preferences_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:changa_app/features/profile/presentation/cubit/preferences_state.dart';

class PreferencesCubit extends Cubit<PreferencesState> {
  PreferencesCubit(this._prefs) : super(const PreferencesState());

  final PreferencesStore _prefs;

  /// Call once at app start, before the first frame that needs the theme.
  Future<void> load() async {
    const defaults = PreferencesState();

    final theme = await _prefs.getString(
      PrefKeys.themeMode,
      fallback: defaults.themeMode.name,
    );
    final nudges = await _prefs.getBool(
      PrefKeys.notifyNudges,
      fallback: defaults.notifyNudges,
    );
    final chores = await _prefs.getBool(
      PrefKeys.notifyChores,
      fallback: defaults.notifyChores,
    );
    final method = await _prefs.getString(
      PrefKeys.defaultSettlementMethod,
      fallback: defaults.defaultSettlementMethod.name,
    );
    final split = await _prefs.getString(
      PrefKeys.defaultSplitType,
      fallback: defaults.defaultSplitType.name,
    );

    var settlement = _byName(
      SettlementMethod.values,
      method,
      defaults.defaultSettlementMethod,
    );
    // Credits are applied automatically, so they are never a default choice.
    if (settlement == SettlementMethod.credits) {
      settlement = defaults.defaultSettlementMethod;
    }

    emit(
      PreferencesState(
        themeMode: _byName(ThemeMode.values, theme, defaults.themeMode),
        notifyNudges: nudges,
        notifyChores: chores,
        defaultSettlementMethod: settlement,
        defaultSplitType: _byName(
          SplitType.values,
          split,
          defaults.defaultSplitType,
        ),
        isLoaded: true,
      ),
    );
  }

  // Each setter updates the screen first, then saves, so the UI never waits.
  // If saving fails the screen goes back to what it was and says so.

  Future<void> setThemeMode(ThemeMode mode) => _change(
    apply: (s) => s.copyWith(themeMode: mode),
    save: () => _prefs.setString(PrefKeys.themeMode, mode.name),
  );

  Future<void> setNotifyNudges(bool value) => _change(
    apply: (s) => s.copyWith(notifyNudges: value),
    save: () => _prefs.setBool(PrefKeys.notifyNudges, value),
  );

  Future<void> setNotifyChores(bool value) => _change(
    apply: (s) => s.copyWith(notifyChores: value),
    save: () => _prefs.setBool(PrefKeys.notifyChores, value),
  );

  Future<void> setDefaultSettlementMethod(SettlementMethod method) {
    if (method == SettlementMethod.credits) return Future.value();
    return _change(
      apply: (s) => s.copyWith(defaultSettlementMethod: method),
      save: () =>
          _prefs.setString(PrefKeys.defaultSettlementMethod, method.name),
    );
  }

  Future<void> setDefaultSplitType(SplitType type) => _change(
    apply: (s) => s.copyWith(defaultSplitType: type),
    save: () => _prefs.setString(PrefKeys.defaultSplitType, type.name),
  );

  void clearSaveError() => emit(state.copyWith(clearSaveError: true));

  Future<void> _change({
    required PreferencesState Function(PreferencesState) apply,
    required Future<void> Function() save,
  }) async {
    final before = state;
    emit(apply(before).copyWith(clearSaveError: true));
    try {
      await save();
    } catch (_) {
      if (isClosed) return;
      emit(
        before.copyWith(
          saveError: 'Couldn’t save that setting. Please try again.',
        ),
      );
    }
  }

  /// A stored value we no longer recognise falls back instead of crashing.
  T _byName<T extends Enum>(Iterable<T> values, String raw, T fallback) =>
      values.asNameMap()[raw] ?? fallback;
}
