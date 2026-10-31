import 'package:shared_preferences/shared_preferences.dart';


class LastRecommendationStorage {
  LastRecommendationStorage({
    Future<SharedPreferences> Function()? preferences,
  }) : _preferences = preferences ?? SharedPreferences.getInstance;

  final Future<SharedPreferences> Function() _preferences;

  Future<String?> read(String key) async {
    final preferences = await _preferences();
    return preferences.getString(key);
  }

  Future<void> write(String key, String value) async {
    final preferences = await _preferences();
    await preferences.setString(key, value);
  }
}
