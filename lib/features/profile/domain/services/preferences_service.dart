abstract class PreferencesService {
  Future<String> getString(String key, {required String fallback});
  Future<bool> getBool(String key, {required bool fallback});
  Future<void> setString(String key, String value);
  Future<void> setBool(String key, bool value);
}
