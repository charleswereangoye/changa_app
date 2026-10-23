import 'package:shared_preferences/shared_preferences.dart';

/// Helper service for local storage using SharedPreferences.
class PreferencesService {
  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  bool getBool(String key, {bool fallback = false}) {
    return _prefs.getBool(key) ?? fallback;
  }

  Future<bool> setBool(String key, bool value) {
    return _prefs.setBool(key, value);
  }

  String getString(String key, {String fallback = ''}) {
    return _prefs.getString(key) ?? fallback;
  }

  Future<bool> setString(String key, String value) {
    return _prefs.setString(key, value);
  }
}
