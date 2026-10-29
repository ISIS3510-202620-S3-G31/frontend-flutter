import '../models/user_location_model.dart';
import 'location_gateway.dart';

/// Why a location reading can be refused. A denied permission and a switched
/// off GPS look the same to the user but are fixed in different settings
/// screens, so they are kept apart.
enum LocationAvailability {
  ready,
  permissionDenied,
  permissionPermanentlyDenied,
  serviceDisabled,

  /// Nothing was refused and the phone still produced no position: no signal
  /// indoors, a timeout, or location settings the app cannot see.
  noReading,
}

/// What came back from asking where the user is.
class LocationReading {
  const LocationReading({
    required this.outcome,
    this.location,
    this.isStale = false,
  });

  final LocationAvailability outcome;

  /// Where the user is, when anything is known at all.
  ///
  /// It can be set even when [outcome] is [LocationAvailability.noReading]:
  /// the phone gave no new position, but the system had kept an older one.
  final UserLocation? location;

  /// The location is older than the service's freshness window, so it says
  /// where the user was, not where they are.
  final bool isStale;

  bool get hasLocation => location != null;

  @override
  String toString() =>
      'LocationReading(${outcome.name}, $location, stale: $isStale)';
}

/// Reads where the user is, once, when somebody asks.
///
/// Permission goes through `permission_handler`, like [MicrophoneService], so
/// the app has one way of asking for permissions. Only `permission_handler`
/// cannot tell whether location is switched off on the phone, which is what
/// the gateway's `isServiceEnabled` is for.
class LocationService {
  /// One shared instance, so the reading is cached for the whole app instead
  /// of once per caller. Pass any argument and you get a separate one, which
  /// is how tests stay independent of each other.
  ///
  /// Same shape as [AnalyticsService], the other service here that has to be
  /// shared because it keeps state.
  factory LocationService({
    LocationGateway? gateway,
    DateTime Function()? now,
    Duration? freshness,
    Duration? timeLimit,
  }) {
    if (gateway != null ||
        now != null ||
        freshness != null ||
        timeLimit != null) {
      return LocationService._internal(gateway, now, freshness, timeLimit);
    }
    return _instance ??= LocationService._internal(null, null, null, null);
  }

  LocationService._internal(
    LocationGateway? gateway,
    DateTime Function()? now,
    Duration? freshness,
    Duration? timeLimit,
  ) : _gateway = gateway ?? const LocationGateway(),
      _now = now ?? DateTime.now,
      freshness = freshness ?? const Duration(minutes: 30),
      timeLimit = timeLimit ?? const Duration(seconds: 10);

  static LocationService? _instance;

  final LocationGateway _gateway;
  final DateTime Function() _now;

  /// How long a reading is reused before the phone is asked again. The weather
  /// of a city does not change with a walk around the block.
  final Duration freshness;

  /// A fix can take a while, or never arrive indoors.
  final Duration timeLimit;

  UserLocation? _cached;

  /// The last reading, fresh or not, without asking the phone for anything.
  UserLocation? get cachedLocation => _cached;

  /// Checks the two things that can stop a reading, and asks for permission
  /// when it has not been granted yet.
  Future<LocationAvailability> ensureAvailable() async {
    if (!await _gateway.isServiceEnabled()) {
      return LocationAvailability.serviceDisabled;
    }
    return switch (await _gateway.requestPermission()) {
      LocationPermissionStatus.granted => LocationAvailability.ready,
      LocationPermissionStatus.denied => LocationAvailability.permissionDenied,
      LocationPermissionStatus.permanentlyDenied =>
        LocationAvailability.permissionPermanentlyDenied,
    };
  }

  /// Where the user is, and why, when the answer is not a fresh reading.
  ///
  /// Answers from the kept reading while it is younger than [freshness]. When
  /// a new reading fails it falls back to whatever the system kept, so a lost
  /// signal degrades to an older city instead of to nothing — and says so
  /// through [LocationReading.isStale].
  Future<LocationReading> currentLocation() async {
    final cached = _cached;
    if (cached != null && cached.isFresherThan(freshness, now: _now())) {
      return LocationReading(
        outcome: LocationAvailability.ready,
        location: cached,
      );
    }

    final availability = await ensureAvailable();
    if (availability != LocationAvailability.ready) {
      return _reading(availability);
    }

    try {
      final position = await _gateway.currentPosition(timeLimit: timeLimit);
      _cached = UserLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        readAt: _now(),
      );
      return _reading(LocationAvailability.ready);
    } on Exception {
      await _lastKnown();
      return _reading(LocationAvailability.noReading);
    }
  }

  /// Wraps whatever is cached, marking it stale when it is past [freshness].
  LocationReading _reading(LocationAvailability outcome) {
    final location = _cached;
    return LocationReading(
      outcome: outcome,
      location: location,
      isStale:
          location != null && !location.isFresherThan(freshness, now: _now()),
    );
  }

  Future<UserLocation?> _lastKnown() async {
    try {
      final position = await _gateway.lastKnownPosition();
      if (position == null) return null;
      // The timestamp is the phone's, not ours: this reading is not fresh and
      // must not pass the freshness check on the next call.
      return _cached = UserLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        readAt: position.timestamp,
      );
    } on Exception {
      return null;
    }
  }

  /// For [LocationAvailability.serviceDisabled]: the phone's location switch.
  Future<void> openLocationSettings() => _gateway.openLocationSettings();

  /// For [LocationAvailability.permissionPermanentlyDenied]: the app's own
  /// permission screen, the only place that decision can be undone.
  ///
  /// Named like [MicrophoneService.openSettings] so the two read the same.
  Future<void> openSettings() => _gateway.openAppSettings();
}
