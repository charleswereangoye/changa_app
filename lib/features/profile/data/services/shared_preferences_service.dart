import 'package:shared_preferences/shared_preferences.dart';

import 'package:changa_app/features/profile/domain/services/preferences_store.dart';

/// Implements the preferences contract used by PreferencesCubit.
///
/// The futures returned by [setString] and [setBool] complete with a
/// [StateError] if SharedPreferences reports that a save failed.
/// Callers must await these methods and catch save failures to provide
/// appropriate feedback to the user.

class SharedPreferencesService implements PreferencesStore {
  const SharedPreferencesService(this._preferences);

  final SharedPreferences _preferences;

  @override
  Future<String> getString(String key, {required String fallback}) async {
    return _preferences.getString(key) ?? fallback;
  }

  @override
  Future<bool> getBool(String key, {required bool fallback}) async {
    return _preferences.getBool(key) ?? fallback;
  }

  @override
  Future<void> setString(String key, String value) async {
    final saved = await _preferences.setString(key, value);

    if (!saved) {
      throw StateError('The preference could not be saved.');
    }
  }

  @override
  Future<void> setBool(String key, bool value) async {
    final saved = await _preferences.setBool(key, value);

    if (!saved) {
      throw StateError('The preference could not be saved.');
    }
  }
}
