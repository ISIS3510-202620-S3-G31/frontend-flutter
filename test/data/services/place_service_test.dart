import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/data/services/location_gateway.dart';
import 'package:frontend_flutter/data/services/location_service.dart';
import 'package:frontend_flutter/data/services/place_service.dart';
import 'package:geocoding/geocoding.dart';

import 'location_fakes.dart';

void main() {
  final now = DateTime(2026, 10, 31, 12);
  late FakeLocationGateway gateway;
  late List<(double, double)> asked;

  setUp(() {
    gateway = FakeLocationGateway(position: positionAt(4.6, -74.08, now));
    asked = [];
  });

  PlaceService serviceAnswering(List<Placemark> Function() answer) =>
      PlaceService(
        location: LocationService(gateway: gateway, now: () => now),
        geocoder: (latitude, longitude) async {
          asked.add((latitude, longitude));
          return answer();
        },
      );

  test('names the city and country the user is in', () async {
    final service = serviceAnswering(
      () => [
        const Placemark(
          locality: 'Bogotá',
          country: 'Colombia',
          isoCountryCode: 'CO',
        ),
      ],
    );

    final place = await service.currentPlace();

    expect(place?.city, 'Bogotá');
    expect(place?.country, 'Colombia');
    expect(place?.countryCode, 'CO');
  });

  test('keeps only the names, never the coordinates', () async {
    final service = serviceAnswering(
      () => [const Placemark(locality: 'Bogotá', country: 'Colombia')],
    );

    final map = (await service.currentPlace())!.toMap();

    expect(map.keys, unorderedEquals(['city', 'country']));
  });

  test(
    'without the permission it neither asks nor looks anything up',
    () async {
      gateway.permission = LocationPermissionStatus.denied;
      final service = serviceAnswering(() => fail('should not geocode'));

      expect(await service.currentPlace(), isNull);
      expect(gateway.prompts, 0);
      expect(asked, isEmpty);
    },
  );

  test('offline, the geocoder fails and there is simply no place', () async {
    final service = serviceAnswering(() => throw Exception('no network'));

    expect(await service.currentPlace(), isNull);
  });

  test('a rural district counts as the municipality it belongs to', () {
    final place = PlaceService.placeOf(
      const Placemark(
        locality: 'Tiquisa',
        subAdministrativeArea: 'Chía',
        administrativeArea: 'Cundinamarca',
        country: 'Colombia',
      ),
    );

    expect(place?.city, 'Chía');
  });

  test('without a municipality the locality is used', () {
    final place = PlaceService.placeOf(
      const Placemark(locality: 'Bogotá', country: 'Colombia'),
    );

    expect(place?.city, 'Bogotá');
  });

  test('a place with no country is not worth keeping', () {
    expect(PlaceService.placeOf(const Placemark(locality: 'Bogotá')), isNull);
  });
}
