/// Where the user is, to the precision the app asks for: enough for the city,
/// not enough to place them in it.
class UserLocation {
  const UserLocation({
    required this.latitude,
    required this.longitude,
    required this.readAt,
  });

  final double latitude;
  final double longitude;

  /// When the phone produced this reading, so callers can tell a fresh fix
  /// from one kept while the signal was gone.
  final DateTime readAt;

  bool isFresherThan(Duration age, {required DateTime now}) =>
      now.difference(readAt) < age;

  @override
  String toString() =>
      'UserLocation($latitude, $longitude, ${readAt.toIso8601String()})';
}
