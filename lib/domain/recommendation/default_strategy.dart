import '../../data/models/recommendation_model.dart';
import '../../data/models/tool_model.dart';
import 'recommendation_strategy.dart';

/// Used when the app knows nothing about the user yet, like a new account.
class DefaultStrategy implements RecommendationStrategy {
  const DefaultStrategy();

  /// Short and good for any mood, so it is a safe first tool.
  static const _starterToolId = 'breathing';

  @override
  Recommendation? recommend(UserHistory history, List<ToolItem> tools) {
    final tool =
        tools.where((tool) => tool.id == _starterToolId).firstOrNull ??
        tools.firstOrNull;
    if (tool == null) return null;
    return Recommendation(tool: tool, reason: 'A gentle place to start.');
  }
}
