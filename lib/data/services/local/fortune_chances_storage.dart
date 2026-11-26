import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// How many cookies each account has left today, in SharedPreferences.
///
/// Two small values per account: the count and the day it belongs to. A new
/// day starts again at [dailyChances] without anything having to reset it.
/// The keys are the Kotlin app's.
class FortuneChancesStorage {
  FortuneChancesStorage({
    Future<SharedPreferences> Function()? preferences,
    DateTime Function()? now,
  }) : _preferences = preferences ?? SharedPreferences.getInstance,
       _now = now ?? DateTime.now;

  static const dailyChances = 5;
  static final _dayFormat = DateFormat('yyyy-MM-dd');

  final Future<SharedPreferences> Function() _preferences;
  final DateTime Function() _now;

  String _today() => _dayFormat.format(_now());

  Future<int> chancesLeft(String userId) async {
    final preferences = await _preferences();
    if (preferences.getString('last_date_$userId') != _today()) {
      return dailyChances;
    }
    return preferences.getInt('chances_left_$userId') ?? dailyChances;
  }

  /// Spends one cookie of today and returns how many are left.
  Future<int> spendOne(String userId) async {
    final preferences = await _preferences();
    final left = (await chancesLeft(userId) - 1).clamp(0, dailyChances);
    await preferences.setString('last_date_$userId', _today());
    await preferences.setInt('chances_left_$userId', left);
    return left;
  }
}
