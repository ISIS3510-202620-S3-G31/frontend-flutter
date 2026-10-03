import '../../data/models/recommendation_model.dart';
import '../../data/models/tool_model.dart';
import 'recommendation_strategy.dart';

/// Looks at the tools the user finished and suggests their favorite kind.
class FrequencyBasedStrategy implements RecommendationStrategy {
  const FrequencyBasedStrategy();

  @override
  Recommendation? recommend(UserHistory history, List<ToolItem> tools) {
    final usesPerCategory = <ToolCategory, int>{};
    for (final tool in tools) {
      final uses = history.usesOf(tool.id);
      if (uses == 0) continue;
      usesPerCategory[tool.category] =
          (usesPerCategory[tool.category] ?? 0) + uses;
    }
    if (usesPerCategory.isEmpty) return null;

    final favorite = usesPerCategory.keys.reduce(
      (a, b) => usesPerCategory[b]! > usesPerCategory[a]! ? b : a,
    );
    final tool = tools
        .where((tool) => tool.category == favorite)
        .reduce((a, b) => history.usesOf(b.id) > history.usesOf(a.id) ? b : a);
    return Recommendation(
      tool: tool,
      reason: 'You often choose ${favorite.label.toLowerCase()} tools.',
    );
  }
}
