import '../models/weather_model.dart';
import '../services/connectivity_service.dart';
import '../services/location_service.dart';
import '../services/remote/weather_service.dart';

/// What came back from asking for the weather where the user is.
enum WeatherOutcome {
  ready,



  noLocation,

  /// No connection: asking again when it comes back should work.
  offline,

  /// The weather service failed or answered something the app cannot read.
  unavailable,
}

class WeatherReading {
  const WeatherReading({required this.outcome, this.weather, this.location});

  final WeatherOutcome outcome;

  final Weather? weather;


  final LocationReading? location;

  bool get hasWeather => weather != null;

  @override
  String toString() => 'WeatherReading(${outcome.name}, $weather, $location)';
}


class WeatherRepository {
  WeatherRepository({
    LocationService? location,
    WeatherService? service,
    ConnectivityService? connectivity,
  }) : _location = location ?? LocationService(),
       _service = service ?? WeatherService(),
       _connectivity = connectivity ?? ConnectivityService();

  final LocationService _location;
  final WeatherService _service;
  final ConnectivityService _connectivity;

  Future<WeatherReading> currentWeather() async {
    final LocationReading reading;
    try {
      reading = await _location.currentLocation();
    } on Exception {
      return const WeatherReading(outcome: WeatherOutcome.noLocation);
    }
    final place = reading.location;
    if (place == null) {
      return WeatherReading(
        outcome: WeatherOutcome.noLocation,
        location: reading,
      );
    }

    // Without a connection, say so now instead of waiting for the request to fail.
    if (!await _isOnline()) {
      return WeatherReading(outcome: WeatherOutcome.offline, location: reading);
    }

    try {
      final weather = await _service.currentWeather(
        latitude: place.latitude,
        longitude: place.longitude,
      );
      return WeatherReading(
        outcome: WeatherOutcome.ready,
        weather: weather,
        location: reading,
      );
    } on WeatherException catch (error) {
      return WeatherReading(
        outcome: error.failure == WeatherFailure.offline
            ? WeatherOutcome.offline
            : WeatherOutcome.unavailable,
        location: reading,
      );
    }
  }

  Stream<bool> get onlineChanges => _connectivity.onlineChanges;

  /// When the check itself fails, the request gets to decide.
  Future<bool> _isOnline() async {
    try {
      return await _connectivity.isOnline();
    } on Exception {
      return true;
    }
  }
}
