import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/data/services/location_gateway.dart';
import 'package:frontend_flutter/data/services/location_service.dart';

import 'location_fakes.dart';

void main() {
  final today = DateTime(2026, 10, 29, 12);
  var clock = today;

  setUp(() => clock = today);

  LocationService serviceWith(FakeLocationGateway gateway) =>
      LocationService(gateway: gateway, now: () => clock);

  group('availability', () {
    test('location switched off is not a denied permission', () async {
      final gateway = FakeLocationGateway(serviceEnabled: false);

      // Reported before the permission is even asked for, because no answer
      // to the prompt would make a reading possible.
      expect(
        await serviceWith(gateway).ensureAvailable(),
        LocationAvailability.serviceDisabled,
      );
    });

    test('a denied permission is told apart from a permanent one', () async {
      final denied = FakeLocationGateway(
        permission: LocationPermissionStatus.denied,
      );
      final forever = FakeLocationGateway(
        permission: LocationPermissionStatus.permanentlyDenied,
      );

      expect(
        await serviceWith(denied).ensureAvailable(),
        LocationAvailability.permissionDenied,
      );
      expect(
        await serviceWith(forever).ensureAvailable(),
        LocationAvailability.permissionPermanentlyDenied,
      );
    });

    test('each refusal has its own settings screen', () async {
      final gateway = FakeLocationGateway();
      final service = serviceWith(gateway);

      await service.openLocationSettings();
      await service.openSettings();

      expect(gateway.openedLocationSettings, 1);
      expect(gateway.openedAppSettings, 1);
    });
  });

  group('reading', () {
    test('reads the phone and keeps the result', () async {
      final gateway = FakeLocationGateway(
        position: positionAt(4.60, -74.08, today),
      );

      final reading = await serviceWith(gateway).currentLocation();

      expect(reading.outcome, LocationAvailability.ready);
      expect(reading.location?.latitude, 4.60);
      expect(reading.location?.longitude, -74.08);
      expect(reading.isStale, isFalse);
      expect(gateway.reads, 1);
    });

    test('nothing is read while the kept reading is fresh', () async {
      final gateway = FakeLocationGateway(
        position: positionAt(4.60, -74.08, today),
      );
      final service = serviceWith(gateway);

      await service.currentLocation();
      clock = today.add(const Duration(minutes: 29));
      await service.currentLocation();

      expect(gateway.reads, 1);
    });

    test('the phone is asked again once the reading goes stale', () async {
      final gateway = FakeLocationGateway(
        position: positionAt(4.60, -74.08, today),
      );
      final service = serviceWith(gateway);

      await service.currentLocation();
      clock = today.add(const Duration(minutes: 31));
      await service.currentLocation();

      expect(gateway.reads, 2);
    });

    test('a failed reading falls back to the one the system kept', () async {
      final yesterday = today.subtract(const Duration(days: 1));
      final gateway = FakeLocationGateway(
        failsToRead: true,
        lastKnown: positionAt(4.60, -74.08, yesterday),
      );

      final reading = await serviceWith(gateway).currentLocation();

      // Nothing was refused: the phone simply gave nothing new.
      expect(reading.outcome, LocationAvailability.noReading);
      expect(reading.location?.latitude, 4.60);
      expect(reading.isStale, isTrue);
      // Carries the phone's timestamp, not ours, so it does not pass as fresh.
      expect(reading.location?.readAt, yesterday);
    });

    test('returns nothing when there is no reading anywhere', () async {
      final gateway = FakeLocationGateway(failsToRead: true);

      final reading = await serviceWith(gateway).currentLocation();

      expect(reading.outcome, LocationAvailability.noReading);
      expect(reading.hasLocation, isFalse);
    });

    test('a refused permission does not reach the phone', () async {
      final gateway = FakeLocationGateway(
        permission: LocationPermissionStatus.denied,
        position: positionAt(4.60, -74.08, today),
      );

      final reading = await serviceWith(gateway).currentLocation();

      expect(reading.outcome, LocationAvailability.permissionDenied);
      expect(reading.hasLocation, isFalse);
      expect(gateway.reads, 0);
    });
  });

  group('instance', () {
    test('callers with no arguments share one instance and its cache', () {
      // The TTL only saves a GPS read if everyone holds the same object.
      expect(identical(LocationService(), LocationService()), isTrue);
    });

    test('passing anything gives a separate instance', () {
      final shared = LocationService();
      final own = LocationService(gateway: FakeLocationGateway());

      expect(identical(shared, own), isFalse);
    });
  });

  group('staleness', () {
    test('a cache hit inside the window is not stale', () async {
      final gateway = FakeLocationGateway(
        position: positionAt(4.60, -74.08, today),
      );
      final service = serviceWith(gateway);

      await service.currentLocation();
      clock = today.add(const Duration(minutes: 20));
      final reading = await service.currentLocation();

      expect(reading.outcome, LocationAvailability.ready);
      expect(reading.isStale, isFalse);
      expect(gateway.reads, 1);
    });

    test(
      'a refusal still hands back what was already known, as stale',
      () async {
        final gateway = FakeLocationGateway(
          position: positionAt(4.60, -74.08, today),
        );
        final service = serviceWith(gateway);

        await service.currentLocation();
        // The user revokes the permission and time moves past the window.
        gateway.permission = LocationPermissionStatus.denied;
        clock = today.add(const Duration(hours: 2));
        final reading = await service.currentLocation();

        expect(reading.outcome, LocationAvailability.permissionDenied);
        expect(reading.location?.latitude, 4.60);
        expect(reading.isStale, isTrue);
      },
    );
  });

  group('reading only if already allowed', () {
    test('never shows the prompt when the permission was not given', () async {
      final gateway = FakeLocationGateway(
        permission: LocationPermissionStatus.denied,
        position: positionAt(4.6, -74.08, today),
      );

      expect(await serviceWith(gateway).locationIfAllowed(), isNull);
      expect(gateway.prompts, 0);
      expect(gateway.reads, 0);
    });

    test('reads where the user is once it was allowed', () async {
      final gateway = FakeLocationGateway(
        position: positionAt(4.6, -74.08, today),
      );

      final location = await serviceWith(gateway).locationIfAllowed();

      expect(location?.latitude, 4.6);
    });

    test('an old position the phone kept is not good enough', () async {
      // The fix fails and only a two-day-old position is left: it could be
      // from another city, so it is not used.
      final gateway = FakeLocationGateway(
        failsToRead: true,
        lastKnown: positionAt(
          6.24,
          -75.58,
          today.subtract(const Duration(days: 2)),
        ),
      );

      expect(await serviceWith(gateway).locationIfAllowed(), isNull);
    });
  });
}
