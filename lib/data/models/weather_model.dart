/// The weather where the user is, the same whatever API it came from.
class Weather {
  const Weather({
    required this.temperatureC,
    required this.precipitationMm,
    required this.weatherCode,
    required this.isDay,
    required this.readAt,
  });


  factory Weather.fromOpenMeteoJson(
    Map<String, dynamic> json, {
    required DateTime readAt,
  }) {
    final current = json['current'];
    if (current is! Map<String, dynamic>) {
      throw const FormatException('Open-Meteo answered without "current".');
    }
    final temperature = current['temperature_2m'];
    final code = current['weather_code'];
    if (temperature is! num || code is! num) {
      throw const FormatException(
        'Open-Meteo answered without temperature or weather code.',
      );
    }
    final rain = current['precipitation'];
    return Weather(
      temperatureC: temperature.toDouble(),
      precipitationMm: rain is num ? rain.toDouble() : 0,
      weatherCode: code.toInt(),
      // 1 by day and 0 by night; without it, day is the safer guess.
      isDay: current['is_day'] != 0,
      readAt: readAt,
    );
  }


  static const coldBelowC = 12.0;
  static const minRainMm = 0.1;

  final double temperatureC;

  final double precipitationMm;


  final int weatherCode;

  final bool isDay;

  final DateTime readAt;

  bool get isRainy =>
      precipitationMm >= minRainMm ||
      (weatherCode >= 51 && weatherCode <= 67) ||
      (weatherCode >= 80 && weatherCode <= 82) ||
      weatherCode >= 95;

  bool get isCold => temperatureC < coldBelowC;

  bool get isClearAndSunny => isDay && weatherCode <= 1 && !isRainy;

  int get roundedTemperature => temperatureC.round();

  @override
  String toString() =>
      'Weather($roundedTemperature °C, code $weatherCode, '
      'rain $precipitationMm mm, ${isDay ? 'day' : 'night'})';
}
