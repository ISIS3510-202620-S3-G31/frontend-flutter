import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/data/models/photo_model.dart';
import 'package:frontend_flutter/data/repositories/analytics_repository.dart';
import 'package:frontend_flutter/data/repositories/photo_repository.dart';
import 'package:frontend_flutter/data/services/camera_service.dart';
import 'package:frontend_flutter/ui/tools/photo/view_model/photo_of_the_day_view_model.dart';

/// The photos this account has, and what the view model asked of them.
class FakePhotoRepository implements PhotoRepository {
  FakePhotoRepository(this.root);

  final Directory root;
  final Map<DateTime, String> stored = {};
  final opened = <DateTime>[];
  final saved = <DateTime>[];

  File _write(DateTime day, String image) {
    final file = File('${root.path}/${day.day}.jpg')..writeAsStringSync(image);
    return file;
  }

  @override
  Future<DailyPhoto?> photoOf(DateTime day) async {
    final image = stored[day];
    return image == null ? null : DailyPhoto(day: day, file: _write(day, image));
  }

  @override
  Future<DailyPhoto?> anyPhotoOf(DateTime day) async {
    opened.add(day);
    return photoOf(day);
  }

  @override
  Future<Set<DateTime>> daysWithPhoto(List<DateTime> days) async =>
      {...stored.keys.where(days.contains)};

  @override
  Future<DailyPhoto> savePhoto(DateTime day, XFile photo) async {
    saved.add(day);
    stored[day] = await photo.readAsString();
    return DailyPhoto(day: day, file: _write(day, stored[day]!));
  }

  @override
  Future<bool> uploadPending() async => true;

  @override
  Future<void> discardSharedLeftovers() async {}

  @override
  Future<void> forgetCached(String userId) async {}

  @override
  Stream<bool> get onlineChanges => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Swallows every event. `implements` rather than `extends` because
/// [AnalyticsRepository] is built by a factory and cannot be subclassed; the
/// view model only ever calls methods that return `Future<void>`.
class FakeAnalytics implements AnalyticsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

/// A phone with no camera, so the view model never needs a real controller.
/// The gallery is the seam that puts a photo under review without one.
class FakeCameraService implements CameraService {
  FakeCameraService(this.picked);

  XFile? picked;

  @override
  Future<List<CameraDescription>> listCameras() async => [];

  @override
  Future<XFile?> pickFromGallery() async => picked;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late Directory root;
  late FakePhotoRepository repository;
  late FakeCameraService camera;
  late PhotoOfTheDayViewModel viewModel;

  setUp(() {
    root = Directory.systemTemp.createTempSync('photo_vm_test');
    final picked = File('${root.path}/picked.jpg')
      ..writeAsStringSync('a new photo');
    repository = FakePhotoRepository(root);
    camera = FakeCameraService(XFile(picked.path));
    viewModel = PhotoOfTheDayViewModel(
      repository: repository,
      cameraService: camera,
      analytics: FakeAnalytics(),
    );
  });

  tearDown(() {
    viewModel.dispose();
    root.deleteSync(recursive: true);
  });

  group('taking a photo', () {
    test('a shot waits for the user instead of being kept at once', () async {
      await viewModel.pickFromGallery();

      expect(viewModel.mode, PhotoViewMode.review);
      expect(viewModel.shownPhoto, isNotNull);
      // Nothing was written: the user has not said yes.
      expect(repository.saved, isEmpty);
      expect(viewModel.isCompleted, isFalse);
    });

    test('taking it again throws the shot away and writes nothing', () async {
      await viewModel.pickFromGallery();
      await viewModel.retakePhoto();

      expect(viewModel.mode, PhotoViewMode.camera);
      expect(viewModel.shownPhoto, isNull);
      expect(repository.saved, isEmpty);
    });

    test('a photo can be retaken as many times as the user wants', () async {
      for (var i = 0; i < 3; i++) {
        await viewModel.pickFromGallery();
        await viewModel.retakePhoto();
      }

      expect(repository.saved, isEmpty);
      expect(viewModel.mode, PhotoViewMode.camera);
    });

    test('keeping it is what saves the day', () async {
      await viewModel.pickFromGallery();
      await viewModel.confirmPhoto();

      expect(repository.saved, [viewModel.today]);
      expect(viewModel.mode, PhotoViewMode.saved);
      expect(viewModel.isCompleted, isTrue);
      // The shutter is done for the day.
      expect(viewModel.canShoot, isFalse);
    });
  });

  group('looking at another day', () {
    late DateTime otherDay;

    setUp(() async {
      otherDay = viewModel.week.first;
      repository.stored[otherDay] = 'from another phone';
      await viewModel.load();
    });

    test('opens the photo of a day with one', () async {
      await viewModel.selectDay(otherDay);

      expect(viewModel.mode, PhotoViewMode.otherDay);
      expect(viewModel.isShowingToday, isFalse);
      expect(viewModel.selectedDay, otherDay);
      expect(viewModel.shownPhoto, isNotNull);
      expect(repository.opened, [otherDay]);
    });

    test('an old day cannot be shot over', () async {
      await viewModel.selectDay(otherDay);

      expect(viewModel.canShoot, isFalse);
    });

    test('comes back to today', () async {
      await viewModel.selectDay(otherDay);
      await viewModel.showToday();

      expect(viewModel.mode, PhotoViewMode.camera);
      expect(viewModel.isShowingToday, isTrue);
      expect(viewModel.selectedDay, viewModel.today);
    });

    test('a day with no photo cannot be opened at all', () async {
      final empty = viewModel.week[3];
      await viewModel.selectDay(empty);

      expect(viewModel.selectedDay, viewModel.today);
      expect(repository.opened, isEmpty);
    });
  });
}
