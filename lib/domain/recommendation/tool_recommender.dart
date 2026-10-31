import '../../data/models/recommendation_model.dart';
import '../../data/models/tool_model.dart';
import 'default_strategy.dart';
import 'frequency_based_strategy.dart';
import 'mood_based_strategy.dart';
import 'recommendation_strategy.dart';
import 'weather_based_strategy.dart';

/// Chooses how to recommend a tool from what the app knows about the user, then lets that strategy pick the tool.
class ToolRecommender {
  static const _minSessions = 3;

  RecommendationStrategy _strategy = const DefaultStrategy();

  /// The strategy that picked the last recommendation.
  RecommendationStrategy get strategy => _strategy;

  /// The first strategy that has something to say wins: the weather where the
  /// user is, then their last check-in, then their habits, and the default as
  /// the last resort.
  Recommendation? recommend(UserHistory history, List<ToolItem> tools) {
    for (final strategy in _strategiesFor(history)) {
      final recommendation = strategy.recommend(history, tools);
      if (recommendation != null) {
        _strategy = strategy;
        return recommendation;
      }
    }
    _strategy = const DefaultStrategy();
    return null;
  }

  List<RecommendationStrategy> _strategiesFor(UserHistory history) => [
    if (history.weather != null) const WeatherBasedStrategy(),
    if (history.recentCheckIns.isNotEmpty) const MoodBasedStrategy(),
    if (history.sessions.length >= _minSessions) const FrequencyBasedStrategy(),
    const DefaultStrategy(),
  ];
}
