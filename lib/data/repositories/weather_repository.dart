import '../models/weather_model.dart';
import '../services/connectivity_service.dart';
import '../services/local/weather_local_storage_service.dart';
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

  /// The weather, when there is one: the fresh one on [WeatherOutcome.ready],
  /// the last known one on [WeatherOutcome.offline] and
  /// [WeatherOutcome.unavailable].
  final Weather? weather;

  final LocationReading? location;

  bool get hasWeather => weather != null;

  @override
  String toString() => 'WeatherReading(${outcome.name}, $weather, $location)';
}


/// The weather where the user is, from the phone's location and the weather
/// API.
///
/// Create it once and reuse it: it is not a singleton and every instance opens
/// its own HTTP client, so one made per read would pile them up. [dispose]
/// releases that client.
class WeatherRepository {
  WeatherRepository({
    LocationService? location,
    WeatherFetcher? service,
    ConnectivityChecker? connectivity,
    WeatherStorage? storage,
  }) : _location = location ?? LocationService(),
       _service = service ?? WeatherService(),
       _connectivity = connectivity ?? ConnectivityService(),
       _storage = storage ?? WeatherLocalStorageService();

  final LocationService _location;
  final WeatherFetcher _service;
  final ConnectivityChecker _connectivity;
  final WeatherStorage _storage;

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
      return WeatherReading(
        outcome: WeatherOutcome.offline,
        weather: await _lastKnown(),
        location: reading,
      );
    }

    try {
      final weather = await _service.currentWeather(
        latitude: place.latitude,
        longitude: place.longitude,
      );
      await _save(weather);
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
        // The API has no cache, so a failed read falls back to the last one
        // this repository kept.
        weather: await _lastKnown(),
        location: reading,
      );
    }
  }

  Stream<bool> get onlineChanges {
    final connectivity = _connectivity;
    if (connectivity is ConnectivityService) {
      return connectivity.onlineChanges;
    }
    return const Stream.empty();
  }

  /// The last weather that was read, so a failed fetch still has something to
  /// show. Null when nothing was ever read.
  Future<Weather?> _lastKnown() async {
    try {
      return await _storage.lastWeather();
    } on Exception {
      return null;
    }
  }

  Future<void> _save(Weather weather) async {
    try {
      await _storage.saveLastWeather(weather);
    } on Exception {
      // A failed save must not fail the read that just succeeded.
    }
  }

  /// When the check itself fails, the request gets to decide.
  Future<bool> _isOnline() async {
    try {
      return await _connectivity.isOnline();
    } on Exception {
      return true;
    }
  }

  /// For [LocationAvailability.serviceDisabled]: the phone's location switch.
  Future<void> openLocationSettings() => _location.openLocationSettings();

  /// For [LocationAvailability.permissionPermanentlyDenied]: the app's own
  /// permission screen, the only place that decision can be undone.
  Future<void> openAppSettings() => _location.openSettings();

  /// Asks for the location permission again after a plain denial.
  Future<LocationAvailability> ensureLocationAvailable() =>
      _location.ensureAvailable();

  /// Releases the HTTP client behind this repository.
  void dispose() => _service.close();
}
