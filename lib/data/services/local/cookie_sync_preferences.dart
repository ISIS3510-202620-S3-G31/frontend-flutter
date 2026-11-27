import 'package:shared_preferences/shared_preferences.dart';

class CookieSyncPreferences {
  const CookieSyncPreferences();

  static String _key(String userId) => 'cookie_jar_downloaded_$userId';

  Future<bool> hasDownloaded(String userId) async =>
      (await SharedPreferences.getInstance()).getBool(_key(userId)) ?? false;

  Future<void> markDownloaded(String userId) async =>
      (await SharedPreferences.getInstance()).setBool(_key(userId), true);
}
