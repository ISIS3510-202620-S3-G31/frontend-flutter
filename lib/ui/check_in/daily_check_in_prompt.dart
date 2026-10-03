import '../../data/repositories/check_in_repository.dart';

/// Decides whether to ask the user how they feel.
///
/// Only the first time they open the app each day: if they already answered,
/// or they were already asked in this run, it keeps quiet until tomorrow.
class DailyCheckInPrompt {
  DailyCheckInPrompt({CheckInRepository? repository})
    : _repository = repository ?? CheckInRepository();

  final CheckInRepository _repository;

  DateTime? _askedOn;

  Future<bool> shouldAsk() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (_askedOn == today) return false;
    _askedOn = today;
    try {
      return await _repository.todaysCheckIn() == null;
    } on Exception {
      // Asking on a failed read would risk a second check-in for the day.
      return false;
    }
  }
}
