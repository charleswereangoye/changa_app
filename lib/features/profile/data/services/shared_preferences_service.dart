import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/services/preferences_service.dart';

/// Implements the preferences contract used by PreferencesCubit.
class SharedPreferencesService implements PreferencesService {
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
