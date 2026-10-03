import '../../data/models/check_in_model.dart';
import '../../data/models/recommendation_model.dart';
import '../../data/models/tool_model.dart';
import '../../data/models/tool_session_model.dart';

/// What the app knows about the user when it picks a tool.
class UserHistory {
  const UserHistory({required this.recentCheckIns, required this.sessions});

  /// Check-ins of the last day.
  final List<CheckIn> recentCheckIns;

  /// Tools the user finished in the last month.
  final List<ToolSession> sessions;

  int usesOf(String toolId) =>
      sessions.where((session) => session.toolId == toolId).length;
}

abstract interface class RecommendationStrategy {
  /// Returns null when this strategy cannot pick a tool from [tools].
  Recommendation? recommend(UserHistory history, List<ToolItem> tools);
}
