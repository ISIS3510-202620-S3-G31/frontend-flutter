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

  /// Today as 2026-11-26, which is also the name of the day's document in
  /// the cloud.
  String today() => _dayFormat.format(_now());

  Future<int> chancesLeft(String userId) async {
    final preferences = await _preferences();
    if (preferences.getString('last_date_$userId') != today()) {
      return dailyChances;
    }
    return preferences.getInt('chances_left_$userId') ?? dailyChances;
  }

  /// Cookies opened today on this phone, or learned from another one.
  Future<int> usedToday(String userId) async =>
      dailyChances - await chancesLeft(userId);

  /// Spends one cookie of today and returns how many are left. It stays
  /// pending until the account knows.
  Future<int> spendOne(String userId) async {
    final preferences = await _preferences();
    final left = (await chancesLeft(userId) - 1).clamp(0, dailyChances);
    await preferences.setString('last_date_$userId', today());
    await preferences.setInt('chances_left_$userId', left);
    await preferences.setBool('daily_pending_$userId', true);
    return left;
  }

  /// Takes what another phone opened today. Never gives a cookie back: the
  /// larger count wins.
  Future<void> raiseUsedToday(String userId, int used) async {
    final safe = used.clamp(0, dailyChances);
    if (safe <= await usedToday(userId)) return;
    final preferences = await _preferences();
    await preferences.setString('last_date_$userId', today());
    await preferences.setInt('chances_left_$userId', dailyChances - safe);
  }

  /// Whether today's count changed here and the account does not know yet.
  Future<bool> isPending(String userId) async =>
      (await _preferences()).getBool('daily_pending_$userId') ?? false;

  Future<void> markSent(String userId) async =>
      (await _preferences()).setBool('daily_pending_$userId', false);
}
