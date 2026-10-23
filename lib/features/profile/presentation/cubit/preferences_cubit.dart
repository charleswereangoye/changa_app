import 'package:changa_app/core/enums/split_type.dart';
import 'package:changa_app/core/enums/settlement_method.dart';
import 'package:changa_app/core/constants/pref_keys.dart';
import 'package:changa_app/features/profile/domain/services/preferences_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:changa_app/features/profile/presentation/cubit/preferences_state.dart';

class PreferencesCubit extends Cubit<PreferencesState> {
  PreferencesCubit(this._prefs) : super(const PreferencesState());

  final PreferencesService _prefs;

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

  Future<void> setThemeMode(ThemeMode mode) async {
    emit(state.copyWith(themeMode: mode));
    await _prefs.setString(PrefKeys.themeMode, mode.name);
  }

  Future<void> setNotifyNudges(bool value) async {
    emit(state.copyWith(notifyNudges: value));
    await _prefs.setBool(PrefKeys.notifyNudges, value);
  }

  Future<void> setNotifyChores(bool value) async {
    emit(state.copyWith(notifyChores: value));
    await _prefs.setBool(PrefKeys.notifyChores, value);
  }

  Future<void> setDefaultSettlementMethod(SettlementMethod method) async {
    if (method == SettlementMethod.credits) return;
    emit(state.copyWith(defaultSettlementMethod: method));
    await _prefs.setString(PrefKeys.defaultSettlementMethod, method.name);
  }

  Future<void> setDefaultSplitType(SplitType type) async {
    emit(state.copyWith(defaultSplitType: type));
    await _prefs.setString(PrefKeys.defaultSplitType, type.name);
  }

  /// A stored value we no longer recognise falls back instead of crashing.
  T _byName<T extends Enum>(Iterable<T> values, String raw, T fallback) =>
      values.asNameMap()[raw] ?? fallback;
}
