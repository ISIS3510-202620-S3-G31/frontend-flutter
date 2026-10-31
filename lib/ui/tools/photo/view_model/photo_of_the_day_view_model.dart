import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../../../data/models/photo_model.dart';
import '../../../../data/repositories/analytics_repository.dart';
import '../../../../data/repositories/photo_repository.dart';
import '../../../../data/services/camera_service.dart';

enum DayState { done, today, future }

/// What the big card is showing.
enum PhotoViewMode {
  /// The live camera, waiting for a shot.
  camera,

  /// A photo just taken and not saved yet: confirm it or take it again.
  review,

  /// Today's photo, already saved.
  saved,

  /// The photo of another day, which cannot be retaken.
  otherDay,
}

class PhotoOfTheDayViewModel extends ChangeNotifier {
  PhotoOfTheDayViewModel({
    PhotoRepository? repository,
    CameraService? cameraService,
    AnalyticsRepository? analytics,
  }) : _repository = repository ?? PhotoRepository(),
       _cameraService = cameraService ?? const CameraService(),
       _analytics = analytics ?? AnalyticsRepository();

  final PhotoRepository _repository;
  final CameraService _cameraService;
  final AnalyticsRepository _analytics;

  final DateTime today = DateUtils.dateOnly(DateTime.now());

  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;
  CameraController? _controller;
  bool _startingCamera = false;
  bool _restartOnResume = false;
  bool _disposed = false;
  StreamSubscription<bool>? _onlineChanges;

  bool _cameraFailed = false;
  bool _flashOn = false;
  bool _busy = false;
  String? _message;

  DailyPhoto? _todayPhoto;
  Set<DateTime> _daysWithPhoto = {};

  late DateTime _selectedDay = today;
  XFile? _pending;
  DailyPhoto? _otherDayPhoto;
  bool _loadingDay = false;

  /// Guards against a slow day arriving after the user moved to another one.
  int _dayLoads = 0;

  CameraController? get cameraController => _controller;
  bool get cameraFailed => _cameraFailed;
  bool get flashOn => _flashOn;
  String? get message => _message;

  /// The day the card is showing; today unless the user picked another one.
  DateTime get selectedDay => _selectedDay;

  bool get isShowingToday => _selectedDay == today;

  /// True while the photo of another day is being fetched.
  bool get loadingDay => _loadingDay;

  PhotoViewMode get mode {
    if (!isShowingToday) return PhotoViewMode.otherDay;
    if (_pending != null) return PhotoViewMode.review;
    if (_todayPhoto != null) return PhotoViewMode.saved;
    return PhotoViewMode.camera;
  }

  /// The image on the card, or null when the camera should show instead.
  File? get shownPhoto => switch (mode) {
    PhotoViewMode.review => File(_pending!.path),
    PhotoViewMode.saved => _todayPhoto?.file,
    PhotoViewMode.otherDay => _otherDayPhoto?.file,
    PhotoViewMode.camera => null,
  };

  bool get canShoot => mode == PhotoViewMode.camera && !_busy;

  /// True while a shot waits to be kept or taken again.
  bool get isReviewing => mode == PhotoViewMode.review;

  bool get isBusy => _busy;

  bool get isCompleted => _todayPhoto != null;

  /// Days of the week the user can open, which are the ones with a photo.
  bool canOpen(DateTime day) => _daysWithPhoto.contains(day);

  int get selectedDayIndex => week.indexOf(_selectedDay);

  bool get canSwitchCamera => _cameras.length > 1;

  List<DateTime> get week {
    final monday = DateUtils.addDaysToDate(today, 1 - today.weekday);
    return [for (var i = 0; i < 7; i++) DateUtils.addDaysToDate(monday, i)];
  }

  List<DayState> get weekStates => [
    for (final day in week)
      if (_daysWithPhoto.contains(day))
        DayState.done
      else if (day == today)
        DayState.today
      else
        DayState.future,
  ];

  Future<void> load() async {
    await _repository.discardSharedLeftovers();
    _todayPhoto = await _repository.photoOf(today);
    _daysWithPhoto = await _repository.daysWithPhoto(week);
    _notify();
    _onlineChanges ??= _repository.onlineChanges.listen((online) {
      if (online) _uploadPending();
    });
    _uploadPending();
    await startCamera();
  }

  Future<void> startCamera() async {
    if (_controller != null ||
        _startingCamera ||
        mode != PhotoViewMode.camera ||
        _disposed) {
      return;
    }
    _startingCamera = true;
    try {
      if (_cameras.isEmpty) {
        _cameras = await _cameraService.listCameras();
        final back = _cameras.indexWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
        );
        _cameraIndex = back == -1 ? 0 : back;
      }
      if (_cameras.isEmpty) {
        throw CameraException('noCamera', 'This device has no camera.');
      }
      final controller = await _cameraService.open(
        _cameras[_cameraIndex],
        flashOn: _flashOn,
      );
      // The screen may have closed, or a photo arrived, meanwhile.
      if (_disposed || mode != PhotoViewMode.camera) {
        await controller.dispose();
        return;
      }
      _controller = controller;
      _cameraFailed = false;
    } on Exception {
      // Permission denied, no camera, emulator without camera.
      _cameraFailed = true;
    } finally {
      _startingCamera = false;
      _notify();
    }
  }

  Future<void> _stopCamera() async {
    final controller = _controller;
    if (controller == null) return;
    _controller = null;
    _notify();
    await controller.dispose();
  }

  // The camera plugin doesn't handle the app lifecycle itself.
  void onAppLifecycleChanged(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive && _controller != null) {
      _restartOnResume = true;
      _stopCamera();
    } else if (state == AppLifecycleState.resumed && _restartOnResume) {
      _restartOnResume = false;
      startCamera();
    }
  }

  Future<void> toggleFlash() async {
    _flashOn = !_flashOn;
    _notify();
    final controller = _controller;
    if (controller != null) {
      await _cameraService.setFlash(controller, _flashOn);
    }
  }

  Future<void> flipCamera() async {
    if (!canSwitchCamera) return;
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    await _stopCamera();
    await startCamera();
  }

  /// Takes the shot and shows it for review. Nothing is saved until
  /// [confirmPhoto], so the user can take it again as many times as they want.
  Future<void> takePhoto() async {
    final controller = _controller;
    if (controller == null || _busy) return;
    _busy = true;
    _notify();
    try {
      _pending = await _cameraService.takePicture(controller);
    } on Exception {
      _message = 'Could not take the photo. Try again.';
    } finally {
      _busy = false;
      _notify();
    }
  }

  Future<void> pickFromGallery() async {
    if (_busy) return;
    _busy = true;
    _notify();
    try {
      final picked = await _cameraService.pickFromGallery();
      // A picked photo is reviewed like a taken one, so both are confirmed
      // the same way.
      if (picked != null) _pending = picked;
    } on Exception {
      _message = 'Could not open the gallery.';
    } finally {
      _busy = false;
      _notify();
    }
  }

  /// Keeps the photo under review as the photo of the day.
  Future<void> confirmPhoto() async {
    final pending = _pending;
    if (pending == null || _busy) return;
    _busy = true;
    _notify();
    try {
      await _save(pending);
      _pending = null;
    } on Exception {
      _message = 'Could not save the photo. Try again.';
    } finally {
      _busy = false;
      _notify();
    }
  }

  /// Throws the shot away and goes back to the camera. Nothing was written, so
  /// there is nothing to undo.
  Future<void> retakePhoto() async {
    if (_pending == null || _busy) return;
    _pending = null;
    _notify();
    await startCamera();
  }

  /// Shows the photo of [day], downloading it when another phone took it.
  ///
  /// Days without a photo are not openable, so tapping one does nothing.
  Future<void> selectDay(DateTime day) async {
    if (day == _selectedDay || (!canOpen(day) && day != today)) return;
    final load = ++_dayLoads;
    _selectedDay = day;
    _otherDayPhoto = null;

    if (day == today) {
      _loadingDay = false;
      _notify();
      await startCamera();
      return;
    }

    // The camera has no business running while another day is on screen.
    await _stopCamera();
    _loadingDay = true;
    _notify();
    final photo = await _repository.anyPhotoOf(day);
    // The user may have moved on while this was in flight.
    if (_disposed || load != _dayLoads) return;
    _otherDayPhoto = photo;
    _loadingDay = false;
    _notify();
  }

  Future<void> showToday() => selectDay(today);

  Future<void> _save(XFile photo) async {
    _todayPhoto = await _repository.savePhoto(today, photo);
    _daysWithPhoto = {..._daysWithPhoto, today};
    _notify();
    await _stopCamera();
    _analytics.logToolStep(
      toolId: 'photo',
      stepName: 'photo_captured',
      stepIndex: _daysWithPhoto.length,
    );
    _analytics.completeToolSession(
      toolId: 'photo',
      toolName: 'Photo of the Day',
    );
    if (!await _uploadPending()) {
      _message = 'Saved on your phone. It will upload later.';
    }
  }

  /// Returns false if nothing could be uploaded; the photos stay pending.
  Future<bool> _uploadPending() async {
    try {
      return await _repository.uploadPending();
    } on Exception catch (error) {
      debugPrint('[PhotoOfTheDay] Upload failed, photos stay pending: $error');
      return false;
    }
  }

  void clearMessage() => _message = null;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _onlineChanges?.cancel();
    _controller?.dispose();
    super.dispose();
  }
}
