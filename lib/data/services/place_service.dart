import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';

import '../models/place_model.dart';
import 'location_service.dart';

/// Turns coordinates into the places that match them. A function rather than
/// the plugin itself, so a test can answer without the phone's geocoder.
typedef ReverseGeocoder =
    Future<List<Placemark>> Function(double latitude, double longitude);

/// The city and country the user is in, for analytics.
///
/// Only ever looks: it uses the location when the user already allowed it and
/// otherwise answers null, without a prompt. The geocoder is the phone's own
/// (Android's or Apple's), which needs the network; offline it answers null
/// too, and whoever asked just goes on without a place.
class PlaceService {
  PlaceService({
    LocationService? location,
    ReverseGeocoder? geocoder,
    Duration? timeLimit,
  }) : _location = location ?? LocationService(),
       _customGeocoder = geocoder,
       timeLimit = timeLimit ?? const Duration(seconds: 10);

  /// English names, so places match across phones in different languages and
  /// the dashboard can put them on a map.
  static const _english = Locale('en', 'US');

  final LocationService _location;
  final ReverseGeocoder? _customGeocoder;

  /// The geocoder can wait on a slow network for a long time.
  final Duration timeLimit;

  late final ReverseGeocoder _geocoder =
      _customGeocoder ?? Geocoding(locale: _english).placemarkFromCoordinates;

  /// Where the user is, or null when that cannot be told without asking.
  Future<Place?> currentPlace() async {
    try {
      final location = await _location.locationIfAllowed();
      if (location == null) return null;
      final found = await _geocoder(
        location.latitude,
        location.longitude,
      ).timeout(timeLimit);
      final place = found.isEmpty ? null : placeOf(found.first);
      debugPrint(
        place == null
            ? '[Place] The geocoder found no city and country there.'
            : '[Place] ${place.city}, ${place.country}',
      );
      return place;
      // The place is extra information gathered in the background, so nothing
      // it throws, not even an Error from a plugin missing in the build, may
      // escape; it is printed instead so it can be traced.
    } on Object catch (error) {
      debugPrint('[Place] Could not tell the place: $error');
      return null;
    }
  }

  /// The city is the municipality. Around towns the locality the geocoder
  /// gives can be a rural district (a vereda like Tiquisa, in Chía) too small
  /// for a map to find, while the municipality always is a city. The locality
  /// and then the region only stand in when the municipality is missing.
  static Place? placeOf(Placemark placemark) {
    final city =
        [
          placemark.subAdministrativeArea,
          placemark.locality,
          placemark.administrativeArea,
        ].firstWhere(
          (name) => name != null && name.trim().isNotEmpty,
          orElse: () => null,
        );
    final country = placemark.country;
    if (city == null || country == null || country.trim().isEmpty) return null;
    final code = placemark.isoCountryCode?.trim();
    return Place(
      city: city.trim(),
      country: country.trim(),
      countryCode: code == null || code.isEmpty ? null : code,
    );
  }
}
