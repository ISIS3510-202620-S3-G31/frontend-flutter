import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/circle_icon_button.dart';
import '../../../core/widgets/screen_header.dart';
import '../view_model/photo_of_the_day_view_model.dart';
import 'shutter_button.dart';
import 'viewfinder.dart';
import 'week_strip.dart';

/// Daily photo journal: one photo per day, and a strip showing which days of
/// the week already have one.
class PhotoOfTheDayScreen extends StatefulWidget {
  const PhotoOfTheDayScreen({super.key, this.viewModel});

  /// Pass one in tests; otherwise the screen builds and disposes its own.
  final PhotoOfTheDayViewModel? viewModel;

  @override
  State<PhotoOfTheDayScreen> createState() => _PhotoOfTheDayScreenState();
}

class _PhotoOfTheDayScreenState extends State<PhotoOfTheDayScreen>
    with WidgetsBindingObserver {
  /// Room for the 84 px shutter plus some breathing space.
  static const _minControlsHeight = 124.0;

  late final PhotoOfTheDayViewModel _viewModel =
      widget.viewModel ?? PhotoOfTheDayViewModel();
  late final bool _ownsViewModel = widget.viewModel == null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _viewModel.addListener(_onViewModelChanged);
    _viewModel.load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _viewModel.removeListener(_onViewModelChanged);
    if (_ownsViewModel) _viewModel.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      _viewModel.onAppLifecycleChanged(state);

  void _onViewModelChanged() {
    final message = _viewModel.errorMessage;
    if (message == null || !mounted) return;
    _viewModel.clearError();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final photo = _viewModel.todayPhoto;
        final camera = _viewModel.cameraController;
        final canShoot = _viewModel.canShoot;

        final Widget? content = photo != null
            ? Image.file(photo, fit: BoxFit.cover)
            : camera != null
            ? _CameraFill(controller: camera)
            : null;

        final viewfinder = Viewfinder(
          date: _viewModel.today,
          content: content,
          showGrid: photo == null,
          hint: _viewModel.cameraFailed
              ? 'Camera not available. Tap to try again, or use the gallery.'
              : 'One photo a day, one new memory',
          flashOn: _viewModel.flashOn,
          onFlash: camera != null ? _viewModel.toggleFlash : null,
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
                    subtitle: DateFormat(
                      'EEEE, MMMM d',
                    ).format(_viewModel.today),
                  ),
                  WeekStrip(states: _viewModel.weekStates),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // 456 px on the 844 px Figma frame, shorter on
                        // smaller phones so the controls always fit.
                        final cardHeight =
                            (constraints.maxHeight - 24 - _minControlsHeight)
                                .clamp(240.0, 456.0);
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              child: SizedBox(
                                width: double.infinity,
                                height: cardHeight,
                                child: _viewModel.cameraFailed && photo == null
                                    ? GestureDetector(
                                        onTap: _viewModel.startCamera,
                                        child: viewfinder,
                                      )
                                    : viewfinder,
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 40,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    CircleIconButton(
                                      asset: 'assets/icons/ic_gallery.svg',
                                      semanticLabel: 'Pick from gallery',
                                      onPressed: canShoot
                                          ? _viewModel.pickFromGallery
                                          : null,
                                    ),
                                    ShutterButton(
                                      onPressed: canShoot && camera != null
                                          ? _viewModel.takePhoto
                                          : null,
                                    ),
                                    CircleIconButton(
                                      asset: 'assets/icons/ic_flip_camera.svg',
                                      semanticLabel: 'Switch camera',
                                      onPressed:
                                          canShoot &&
                                              camera != null &&
                                              _viewModel.canSwitchCamera
                                          ? _viewModel.flipCamera
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
      },
    );
  }
}

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
