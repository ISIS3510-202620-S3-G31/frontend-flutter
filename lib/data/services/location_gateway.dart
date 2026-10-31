import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

/// What the user answered to the location permission prompt.
enum LocationPermissionStatus { granted, denied, permanentlyDenied }

/// Every platform call about location goes through here.
///
/// Both geolocator and `permission_handler` work through static calls, which a
/// test cannot replace, so [LocationService] depends on this instead of on
/// them. Keeping them together also keeps the platform boundary in one file.
class LocationGateway {
  const LocationGateway();

  /// Whether location is switched on for the phone, which is not the same as
  /// the app having permission and cannot be read from `permission_handler`.
  Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();

  /// Whether the user already let the app read the location. Only looks:
  /// unlike [requestPermission], it never shows the prompt.
  Future<bool> hasPermission() async {
    final status = await ph.Permission.location.status;
    return status.isGranted || status.isLimited;
  }

  Future<LocationPermissionStatus> requestPermission() async {
    final status = await ph.Permission.location.request();
    // Limited is iOS granting approximate location, which is all the app asks
    // for anyway.
    if (status.isGranted || status.isLimited) {
      return LocationPermissionStatus.granted;
    }
    return status.isPermanentlyDenied
        ? LocationPermissionStatus.permanentlyDenied
        : LocationPermissionStatus.denied;
  }

  /// Low accuracy: towers and Wi-Fi instead of a GPS fix, which answers in
  /// about a second and is already finer than a city.
  Future<Position> currentPosition({Duration? timeLimit}) =>
      Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: timeLimit,
        ),
      );

  /// The reading the operating system kept from whoever asked last. Free, and
  /// null on a phone that has never had a fix.
  Future<Position?> lastKnownPosition() => Geolocator.getLastKnownPosition();

  Future<void> openLocationSettings() => Geolocator.openLocationSettings();

  Future<void> openAppSettings() => ph.openAppSettings();
}
