import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../../../data/models/photo_model.dart';
import '../../../../data/repositories/photo_repository.dart';
import '../../../../data/services/camera_service.dart';

enum DayState { done, today, future }

class PhotoOfTheDayViewModel extends ChangeNotifier {
  PhotoOfTheDayViewModel({
    PhotoRepository? repository,
    CameraService? cameraService,
  }) : _repository = repository ?? PhotoRepository(),
       _cameraService = cameraService ?? const CameraService();

  final PhotoRepository _repository;
  final CameraService _cameraService;

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

  CameraController? get cameraController => _controller;
  bool get cameraFailed => _cameraFailed;
  bool get flashOn => _flashOn;
  File? get todayPhoto => _todayPhoto?.file;
  String? get message => _message;

  bool get canShoot => _todayPhoto == null && !_busy;

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
        _todayPhoto != null ||
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
      // The screen may have closed, or a gallery photo arrived, meanwhile.
      if (_disposed || _todayPhoto != null) {
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

  Future<void> takePhoto() async {
    final controller = _controller;
    if (controller == null || _busy) return;
    _busy = true;
    _notify();
    try {
      await _save(await _cameraService.takePicture(controller));
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
      if (picked != null) await _save(picked);
    } on Exception {
      _message = 'Could not open the gallery.';
    } finally {
      _busy = false;
      _notify();
    }
  }

  Future<void> _save(XFile photo) async {
    _todayPhoto = await _repository.savePhoto(today, photo);
    _daysWithPhoto = {..._daysWithPhoto, today};
    _notify();
    await _stopCamera();
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
