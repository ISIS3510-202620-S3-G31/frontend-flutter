import '../../data/models/recommendation_model.dart';
import '../../data/models/tool_model.dart';
import 'recommendation_strategy.dart';

/// Picks a tool for the weather where the user is right now: rain and cold call
/// for staying in, sun for going out, and mild weather falls back to a calm
/// pick — so there is always a weather recommendation once the weather is
/// known. Null only when the weather could not be read at all.
class WeatherBasedStrategy implements RecommendationStrategy {
  const WeatherBasedStrategy();

  @override
  Recommendation? recommend(UserHistory history, List<ToolItem> tools) {
    final weather = history.weather;
    if (weather == null) return null;

    final String toolId;
    final String reason;
    if (weather.isRainy) {
      toolId = 'breathing';
      reason =
          "It's raining and ${weather.roundedTemperature}°C where you are — "
          'a good moment to breathe inside.';
    } else if (weather.isCold) {
      toolId = 'scream';
      reason =
          "It's ${weather.roundedTemperature}°C and cold where you are — "
          'let it out in the scream tank.';
    } else if (weather.isClearAndSunny) {
      toolId = 'photo';
      reason =
          "It's ${weather.roundedTemperature}°C and sunny where you are — "
          'perfect for a photo of the day.';
    } else {
      toolId = 'breathing';
      reason =
          "It's ${weather.roundedTemperature}°C and mild where you are — "
          'a good moment for a calm breath.';
    }

    final tool = tools.where((tool) => tool.id == toolId).firstOrNull;
    if (tool == null) return null;
    return Recommendation(tool: tool, reason: reason);
  }
}
