import '../../data/models/tool_model.dart';
import '../../data/models/weather_model.dart';

enum WeatherCondition { rainy, cold, sunny }

class WeatherSuggestion {
  const WeatherSuggestion({
    required this.tool,
    required this.condition,
    required this.reason,
  });

  final ToolItem tool;
  final WeatherCondition condition;

  final String reason;

 
  static WeatherSuggestion? forWeather(Weather weather, List<ToolItem> tools) {
    final condition = conditionOf(weather);
    if (condition == null) return null;

    final toolId = switch (condition) {
      WeatherCondition.rainy || WeatherCondition.cold => 'breathing',
      WeatherCondition.sunny => 'photo',
    };
    final tool = tools.where((tool) => tool.id == toolId).firstOrNull;
    if (tool == null) return null;

    final degrees = '${weather.roundedTemperature}°C';
    return WeatherSuggestion(
      tool: tool,
      condition: condition,
      reason: switch (condition) {
        WeatherCondition.rainy => 'Rainy and $degrees outside',
        WeatherCondition.cold => 'Cold day, $degrees outside',
        WeatherCondition.sunny => 'Sunny and $degrees outside',
      },
    );
  }

  /// Rain weighs more than cold: a cold, rainy day counts as rainy.
  static WeatherCondition? conditionOf(Weather weather) {
    if (weather.isRainy) return WeatherCondition.rainy;
    if (weather.isCold) return WeatherCondition.cold;
    if (weather.isClearAndSunny) return WeatherCondition.sunny;
    return null;
  }
}
