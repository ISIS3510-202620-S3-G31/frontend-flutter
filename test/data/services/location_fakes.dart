import 'package:frontend_flutter/data/services/location_gateway.dart';
import 'package:geolocator/geolocator.dart';

/// Stands in for the phone: answers what a test tells it to.
class FakeLocationGateway implements LocationGateway {
  FakeLocationGateway({
    this.serviceEnabled = true,
    this.permission = LocationPermissionStatus.granted,
    this.position,
    this.lastKnown,
    this.failsToRead = false,
  });

  bool serviceEnabled;
  LocationPermissionStatus permission;
  Position? position;
  Position? lastKnown;
  bool failsToRead;

  int reads = 0;
  int openedLocationSettings = 0;
  int openedAppSettings = 0;

  @override
  Future<bool> isServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermissionStatus> requestPermission() async {
    prompts++;
    return permission;
  }

  /// Times the permission prompt would have been shown.
  int prompts = 0;

  @override
  Future<bool> hasPermission() async =>
      permission == LocationPermissionStatus.granted;

  @override
  Future<Position> currentPosition({Duration? timeLimit}) async {
    reads++;
    if (failsToRead) throw const _ReadFailed();
    return position!;
  }

  @override
  Future<Position?> lastKnownPosition() async => lastKnown;

  @override
  Future<void> openLocationSettings() async => openedLocationSettings++;

  @override
  Future<void> openAppSettings() async => openedAppSettings++;
}

class _ReadFailed implements Exception {
  const _ReadFailed();
}

Position positionAt(double lat, double lon, DateTime when) => Position(
  latitude: lat,
  longitude: lon,
  timestamp: when,
  accuracy: 100,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);
