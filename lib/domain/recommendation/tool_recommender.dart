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
  RecommendationStrategy _weatherStrategy = const WeatherBasedStrategy();

  /// The strategy that picked the last personal recommendation.
  RecommendationStrategy get strategy => _strategy;

  /// The strategy that picked the last weather recommendation.
  RecommendationStrategy get weatherStrategy => _weatherStrategy;


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


  Recommendation? weatherRecommendation(
    UserHistory history,
    List<ToolItem> tools,
  ) {
    const strategy = WeatherBasedStrategy();
    _weatherStrategy = strategy;
    return strategy.recommend(history, tools);
  }

  List<RecommendationStrategy> _strategiesFor(UserHistory history) => [
    if (history.recentCheckIns.isNotEmpty) const MoodBasedStrategy(),
    if (history.sessions.length >= _minSessions) const FrequencyBasedStrategy(),
    const DefaultStrategy(),
  ];
}
