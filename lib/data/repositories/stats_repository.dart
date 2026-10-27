import '../models/check_in_model.dart';
import '../models/tool_feedback_model.dart';
import '../models/tool_session_model.dart';
import '../services/local/sample_stats_service.dart';
import 'check_in_repository.dart';
import 'feedback_repository.dart';

/// What the stats screen needs, and whether it is the user's own history.
class StatsData {
  const StatsData({
    required this.checkIns,
    required this.sessions,
    required this.isSample,
  });

  final List<CheckIn> checkIns;
  final List<ToolSession> sessions;

  /// True while the user has no feedback of their own, so the screen can say
  /// that the numbers are an example.
  final bool isSample;
}

class StatsRepository {
  StatsRepository({
    SampleStatsService? source,
    FeedbackRepository? feedback,
    CheckInRepository? checkIns,
  }) : _source = source ?? SampleStatsService(),
       _feedback = feedback ?? FeedbackRepository(),
       _checkIns = checkIns ?? CheckInRepository();

  final SampleStatsService _source;
  final FeedbackRepository _feedback;
  final CheckInRepository _checkIns;

  /// The user's own history since [from], or the sample one until they answer
  /// their first feedback.
  Future<StatsData> dataSince(DateTime from) async {
    // Without a connection, or while the user has no history, the screen still
    // has something to show instead of staying empty.
    final feedback = await _orEmpty(_feedback.since(from));
    final checkIns = await _orEmpty(_checkIns.since(from));
    if (feedback.isNotEmpty || checkIns.isNotEmpty) {
      return StatsData(
        // The user's own check-ins when there are any; until then, the mood
        // they picked after each tool.
        checkIns: checkIns.isNotEmpty
            ? checkIns
            : [for (final one in feedback) _checkInOf(one)],
        sessions: [for (final one in feedback) _sessionOf(one)],
        isSample: false,
      );
    }
    return StatsData(
      checkIns: [
        for (final checkIn in await _source.checkIns())
          if (!checkIn.timestamp.isBefore(from)) checkIn,
      ],
      sessions: [
        for (final session in await _source.toolSessions())
          if (!session.startedAt.isBefore(from)) session,
      ],
      isSample: true,
    );
  }

  /// A failed read should not leave the screen empty.
  static Future<List<T>> _orEmpty<T>(Future<List<T>> read) async {
    try {
      return await read;
    } on Exception {
      return [];
    }
  }

  static ToolSession _sessionOf(ToolFeedback feedback) => ToolSession(
    toolId: feedback.toolId,
    startedAt: feedback.startedAt,
    durationSeconds: feedback.durationSeconds,
  );

  /// Feedback is answered right after a tool, so every mood it offers is a
  /// good one. Until the app has its own check-in screen, they all count as
  /// happiness, and the rating gives the intensity.
  static CheckIn _checkInOf(ToolFeedback feedback) => CheckIn(
    emotions: const [Emotion.happiness],
    intensity: ((feedback.rating + 1) / 2).round().clamp(1, 5),
    timestamp: feedback.startedAt,
  );
}
