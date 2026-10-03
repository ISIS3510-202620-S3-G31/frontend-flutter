import '../../data/models/recommendation_model.dart';
import '../../data/models/tool_model.dart';
import 'default_strategy.dart';
import 'frequency_based_strategy.dart';
import 'mood_based_strategy.dart';
import 'recommendation_strategy.dart';

/// Chooses how to recommend a tool from what the app knows about the user, then lets that strategy pick the tool.
class ToolRecommender {
  static const _minSessions = 3;

  RecommendationStrategy _strategy = const DefaultStrategy();

  /// The strategy used in the last recommendation.
  RecommendationStrategy get strategy => _strategy;

  Recommendation? recommend(UserHistory history, List<ToolItem> tools) {
    _strategy = _strategyFor(history);
    return _strategy.recommend(history, tools) ??
        const DefaultStrategy().recommend(history, tools);
  }

  RecommendationStrategy _strategyFor(UserHistory history) {
    if (history.recentCheckIns.isNotEmpty) return const MoodBasedStrategy();
    if (history.sessions.length >= _minSessions) {
      return const FrequencyBasedStrategy();
    }
    return const DefaultStrategy();
  }
}
