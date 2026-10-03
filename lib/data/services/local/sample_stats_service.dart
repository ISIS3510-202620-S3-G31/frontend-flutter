import '../../models/check_in_model.dart';
import '../../models/tool_session_model.dart';

/// Check-ins and tool sessions for the stats screen.
///
/// The Flutter app does not record check-ins or tool sessions yet, so for now
/// this returns a sample history dated relative to today. When those features
/// save their own records, only this class changes.
class SampleStatsService {
  SampleStatsService({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  Future<List<CheckIn>> checkIns() async => [
    _checkIn(0, 9, [Emotion.happiness], 4),
    _checkIn(1, 20, [Emotion.fear], 3),
    _checkIn(2, 21, [Emotion.sadness], 2),
    _checkIn(3, 19, [Emotion.anger], 4),
    _checkIn(4, 10, [Emotion.happiness, Emotion.surprise], 4),
    _checkIn(5, 8, [Emotion.happiness], 3),
    _checkIn(6, 13, [Emotion.happiness], 3),
    _checkIn(7, 20, [Emotion.anger], 4),
    _checkIn(8, 22, [Emotion.sadness], 4),
    _checkIn(9, 21, [Emotion.fear], 5),
    _checkIn(10, 9, [Emotion.happiness], 2),
    _checkIn(11, 19, [Emotion.disgust], 3),
    _checkIn(12, 20, [Emotion.sadness], 4),
    _checkIn(13, 18, [Emotion.fear, Emotion.surprise], 3),
  ];

  Future<List<ToolSession>> toolSessions() async => [
    for (final day in [0, 3, 5, 6, 9, 10, 15, 20, 25])
      _session(day, 'breathing', 300),
    for (final day in [1, 2, 4, 8, 12]) _session(day, 'photo', 60),
    for (final day in [7, 11, 14]) _session(day, 'jar', 120),
    for (final day in [13, 16]) _session(day, 'blow', 90),
  ];

  CheckIn _checkIn(
    int daysAgo,
    int hour,
    List<Emotion> emotions,
    int intensity,
  ) => CheckIn(
    emotions: emotions,
    intensity: intensity,
    timestamp: _at(daysAgo, hour),
  );

  ToolSession _session(int daysAgo, String toolId, int seconds) => ToolSession(
    toolId: toolId,
    startedAt: _at(daysAgo, 18),
    durationSeconds: seconds,
  );

  DateTime _at(int daysAgo, int hour) {
    final now = _now();
    return DateTime(now.year, now.month, now.day - daysAgo, hour);
  }
}
