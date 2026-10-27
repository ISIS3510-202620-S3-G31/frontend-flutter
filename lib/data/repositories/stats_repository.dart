import '../models/check_in_model.dart';
import '../models/tool_feedback_model.dart';
import '../models/tool_session_model.dart';
import 'check_in_repository.dart';
import 'feedback_repository.dart';

/// What the stats screen needs, always the user's own history.
class StatsData {
  const StatsData({required this.checkIns, required this.sessions});

  final List<CheckIn> checkIns;
  final List<ToolSession> sessions;

  /// True while the user has recorded nothing, so the screen can say so
  /// instead of drawing charts with no numbers behind them.
  bool get isEmpty => checkIns.isEmpty && sessions.isEmpty;
}

class StatsRepository {
  StatsRepository({FeedbackRepository? feedback, CheckInRepository? checkIns})
    : _feedback = feedback ?? FeedbackRepository(),
      _checkIns = checkIns ?? CheckInRepository();

  final FeedbackRepository _feedback;
  final CheckInRepository _checkIns;

  /// The user's own history since [from].
  Future<StatsData> dataSince(DateTime from) async {
    final feedback = await _orEmpty(_feedback.since(from));
    final checkIns = await _orEmpty(_checkIns.since(from));
    return StatsData(
      checkIns: checkIns,
      sessions: [for (final one in feedback) _sessionOf(one)],
    );
  }

  /// A failed read should not look like a different history.
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
}
