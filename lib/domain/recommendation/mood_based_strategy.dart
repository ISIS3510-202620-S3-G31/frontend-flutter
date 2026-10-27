import '../../data/models/check_in_model.dart';
import '../../data/models/recommendation_model.dart';
import '../../data/models/tool_model.dart';
import 'recommendation_strategy.dart';

/// Looks at the last check-in and suggests a tool that helps with that emotion.
class MoodBasedStrategy implements RecommendationStrategy {
  const MoodBasedStrategy();

  /// Tools that fit each emotion, best first.
  static const _toolsFor = {
    Emotion.anger: ['scream', 'tear'],
    Emotion.disgust: ['tear', 'scream'],
    Emotion.fear: ['breathing', 'detective'],
    Emotion.sadness: ['detective', 'breathing'],
    Emotion.happiness: ['photo'],
    Emotion.surprise: ['photo', 'detective'],
  };

  @override
  Recommendation? recommend(UserHistory history, List<ToolItem> tools) {
    if (history.recentCheckIns.isEmpty) return null;
    final last = history.recentCheckIns.reduce(
      (a, b) => b.timestamp.isAfter(a.timestamp) ? b : a,
    );
    if (last.emotions.isEmpty) return null;

    // A difficult emotion matters more than a pleasant one in the same check-in.
    final emotion = last.emotions.firstWhere(
      (emotion) => emotion.isDifficult,
      orElse: () => last.emotions.first,
    );
    final candidates = [
      for (final id in _toolsFor[emotion]!)
        ...tools.where((tool) => tool.id == id),
    ];
    if (candidates.isEmpty) return null;

    // Among the tools that fit, the one the user already uses the most.
    final tool = candidates.reduce(
      (a, b) => history.usesOf(b.id) > history.usesOf(a.id) ? b : a,
    );
    return Recommendation(
      tool: tool,
      reason: 'You felt ${emotion.label.toLowerCase()} in your last check-in.',
    );
  }
}
