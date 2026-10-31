import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/data/models/check_in_model.dart';
import 'package:frontend_flutter/data/models/place_model.dart';
import 'package:frontend_flutter/data/repositories/check_in_repository.dart';
import 'package:frontend_flutter/data/services/place_service.dart';
import 'package:frontend_flutter/data/services/remote/check_in_firestore_service.dart';

import 'photo_fakes.dart' show FakeAuth;

/// What would have reached Firestore, in order.
class FakeCheckInService extends CheckInFirestoreService {
  final writes = <String>[];

  @override
  Future<void> save(String userId, CheckIn checkIn) async =>
      writes.add('check-in');

  @override
  Future<void> addPlace(String userId, DateTime day, Place place) async =>
      writes.add('place ${place.city}');
}

/// Holds its answer back until the test lets it go, like a slow GPS fix.
class FakePlaceService extends PlaceService {
  FakePlaceService(this.answer);

  final Place? answer;
  final gate = Completer<void>();

  @override
  Future<Place?> currentPlace() async {
    await gate.future;
    return answer;
  }
}

void main() {
  final checkIn = CheckIn(
    emotions: const [Emotion.happiness],
    intensity: 3,
    timestamp: DateTime(2026, 10, 31, 9),
    note: '',
  );
  const bogota = Place(city: 'Bogotá', country: 'Colombia', countryCode: 'CO');

  late FakeCheckInService service;

  CheckInRepository repositoryWith(FakePlaceService places) =>
      CheckInRepository(
        service: service,
        auth: FakeAuth('ana'),
        places: places,
      );

  setUp(() => service = FakeCheckInService());

  test('the check-in is saved without waiting to know the city', () async {
    final places = FakePlaceService(bogota);

    await repositoryWith(places).save(checkIn);

    expect(service.writes, ['check-in']);

    places.gate.complete();
    await pumpEventQueue();
    expect(service.writes, ['check-in', 'place Bogotá']);
  });

  test('when the city cannot be told, the check-in stays as it is', () async {
    final places = FakePlaceService(null)..gate.complete();

    await repositoryWith(places).save(checkIn);
    await pumpEventQueue();

    expect(service.writes, ['check-in']);
  });
}
