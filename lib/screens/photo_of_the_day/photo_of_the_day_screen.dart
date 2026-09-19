import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/circle_icon_button.dart';
import '../../widgets/screen_header.dart';
import 'photo_store.dart';
import 'shutter_button.dart';
import 'viewfinder.dart';
import 'week_strip.dart';

/// Daily photo journal: the user takes one photo per day, and the week strip
/// shows which days already have one.
class PhotoOfTheDayScreen extends StatefulWidget {
  const PhotoOfTheDayScreen({super.key});

  @override
  State<PhotoOfTheDayScreen> createState() => _PhotoOfTheDayScreenState();
}

class _PhotoOfTheDayScreenState extends State<PhotoOfTheDayScreen>
    with WidgetsBindingObserver {
  /// Room for the 84 px shutter plus some breathing space.
  static const _minControlsHeight = 124.0;

  final _store = PhotoStore();
  final _today = DateUtils.dateOnly(DateTime.now());

  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;
  CameraController? _camera;
  bool _startingCamera = false;
  bool _cameraFailed = false;
  bool _restartOnResume = false;
  bool _flashOn = false;
  bool _busy = false;

  File? _todayPhoto;
  Set<DateTime> _daysWithPhoto = {};

  List<DateTime> get _week {
    final monday = DateUtils.addDaysToDate(_today, 1 - _today.weekday);
    return [for (var i = 0; i < 7; i++) DateUtils.addDaysToDate(monday, i)];
  }

  List<DayState> get _weekStates => [
    for (final day in _week)
      if (_daysWithPhoto.contains(day))
        DayState.done
      else if (day == _today)
        DayState.today
      else
        DayState.future,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camera?.dispose();
    super.dispose();
  }

  // The camera plugin doesn't handle the app lifecycle: release the camera
  // when the app goes to the background and reopen it when it comes back.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive && _camera != null) {
      _restartOnResume = true;
      _stopCamera();
    } else if (state == AppLifecycleState.resumed && _restartOnResume) {
      _restartOnResume = false;
      _startCamera();
    }
  }

  Future<void> _load() async {
    final photo = await _store.photoFor(_today);
    final days = await _store.daysWithPhoto(_week);
    if (!mounted) return;
    setState(() {
      _todayPhoto = photo;
      _daysWithPhoto = days;
    });
    await _startCamera();
  }

  Future<void> _startCamera() async {
    // One photo a day: once today's photo exists the camera isn't needed.
    if (_camera != null || _startingCamera || _todayPhoto != null) return;
    _startingCamera = true;
    CameraController? controller;
    try {
      if (_cameras.isEmpty) {
        _cameras = await availableCameras();
        final back = _cameras.indexWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
        );
        _cameraIndex = back == -1 ? 0 : back;
      }
      if (_cameras.isEmpty) {
        throw CameraException('noCamera', 'This device has no camera.');
      }
      controller = CameraController(
        _cameras[_cameraIndex],
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      await _applyFlash(controller);
      // The screen may have closed, or a gallery photo arrived, meanwhile.
      if (!mounted || _todayPhoto != null) {
        await controller.dispose();
        return;
      }
      setState(() {
        _camera = controller;
        _cameraFailed = false;
      });
    } on Exception {
      // Permission denied, no camera, emulator without camera…
      await controller?.dispose();
      if (mounted) setState(() => _cameraFailed = true);
    } finally {
      _startingCamera = false;
    }
  }

  Future<void> _stopCamera() async {
    final controller = _camera;
    if (controller == null) return;
    setState(() => _camera = null);
    await controller.dispose();
  }

  Future<void> _applyFlash(CameraController controller) async {
    try {
      await controller.setFlashMode(
        _flashOn ? FlashMode.always : FlashMode.off,
      );
    } on CameraException {
      // Most front cameras have no flash.
    }
  }

  Future<void> _toggleFlash() async {
    setState(() => _flashOn = !_flashOn);
    final controller = _camera;
    if (controller != null) await _applyFlash(controller);
  }

  Future<void> _flipCamera() async {
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    await _stopCamera();
    await _startCamera();
  }

  Future<void> _takePhoto() async {
    final controller = _camera;
    if (controller == null) return;
    setState(() => _busy = true);
    try {
      await _savePhoto(await controller.takePicture());
    } on Exception {
      _showError('Could not take the photo. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickFromGallery() async {
    setState(() => _busy = true);
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        imageQuality: 90,
      );
      if (picked != null) await _savePhoto(picked);
    } on Exception {
      _showError('Could not open the gallery.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _savePhoto(XFile photo) async {
    final file = await _store.save(_today, photo);
    if (!mounted) return;
    setState(() {
      _todayPhoto = file;
      _daysWithPhoto = {..._daysWithPhoto, _today};
    });
    await _stopCamera();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final photo = _todayPhoto;
    final camera = _camera;
    final canShoot = photo == null && !_busy;

    final Widget? content = photo != null
        ? Image.file(photo, fit: BoxFit.cover)
        : camera != null
        ? _CameraFill(controller: camera)
        : null;

    final viewfinder = Viewfinder(
      date: _today,
      content: content,
      showGrid: photo == null,
      hint: _cameraFailed
          ? 'Camera not available. Tap to try again, or use the gallery.'
          : 'One photo a day, one new memory',
      flashOn: _flashOn,
      onFlash: camera != null ? _toggleFlash : null,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              ScreenHeader(
                title: Text('Photo of the day', style: AppText.h1),
                subtitle: DateFormat('EEEE, MMMM d').format(_today),
              ),
              WeekStrip(states: _weekStates),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // 456 px on the 844 px Figma frame; shorter phones get a
                    // shorter card so the controls always fit.
                    final cardHeight =
                        (constraints.maxHeight - 24 - _minControlsHeight).clamp(
                          240.0,
                          456.0,
                        );
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                          child: SizedBox(
                            width: double.infinity,
                            height: cardHeight,
                            child: _cameraFailed && photo == null
                                ? GestureDetector(
                                    onTap: _startCamera,
                                    child: viewfinder,
                                  )
                                : viewfinder,
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                CircleIconButton(
                                  asset: 'assets/icons/ic_gallery.svg',
                                  semanticLabel: 'Pick from gallery',
                                  onPressed: canShoot ? _pickFromGallery : null,
                                ),
                                ShutterButton(
                                  onPressed: canShoot && camera != null
                                      ? _takePhoto
                                      : null,
                                ),
                                CircleIconButton(
                                  asset: 'assets/icons/ic_flip_camera.svg',
                                  semanticLabel: 'Switch camera',
                                  onPressed:
                                      canShoot &&
                                          camera != null &&
                                          _cameras.length > 1
                                      ? _flipCamera
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

/// Camera preview scaled to cover the whole card, like `BoxFit.cover`.
class _CameraFill extends StatelessWidget {
  const _CameraFill({required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    // previewSize is reported in landscape; swap it for a portrait screen.
    final size = controller.value.previewSize ?? const Size(4, 3);
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: size.height,
        height: size.width,
        child: CameraPreview(controller),
      ),
    );
  }
}
