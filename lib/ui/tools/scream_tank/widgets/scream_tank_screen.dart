import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/circle_icon_button.dart';
import '../../../core/widgets/screen_header.dart';
import '../view_model/scream_tank_view_model.dart';
import 'intensity_meter.dart';
import 'mic_button.dart';
import 'tank_illustration.dart';

/// The user screams into the phone: the mic level drives the intensity meter,
/// and loudness accumulated over time fills the tank.
class ScreamTankScreen extends StatefulWidget {
  const ScreamTankScreen({super.key, this.viewModel});

  /// Pass one in tests; otherwise the screen builds and disposes its own.
  final ScreamTankViewModel? viewModel;

  @override
  State<ScreamTankScreen> createState() => _ScreamTankScreenState();
}

class _ScreamTankScreenState extends State<ScreamTankScreen>
    with WidgetsBindingObserver {
  /// Room for the 116 px mic button plus some breathing space.
  static const _minControlsHeight = 140.0;
  static const _meterHeight = 75.0;

  late final ScreamTankViewModel _viewModel =
      widget.viewModel ?? ScreamTankViewModel();
  late final bool _ownsViewModel = widget.viewModel == null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _viewModel.addListener(_onViewModelChanged);
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
    final canOpenSettings = _viewModel.canOpenSettings;
    _viewModel.clearError();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: canOpenSettings
            ? SnackBarAction(
                label: 'Settings',
                onPressed: _viewModel.openSettings,
              )
            : null,
      ),
    );
  }

  void _finishSession() {
    _viewModel.stopListening();
    Navigator.maybePop(context, _viewModel.isFull);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.dark,
          child: Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  const ScreenHeader(title: ScreamTankWordmark()),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // 480 px on the 844 px Figma frame, shorter on smaller
                        // phones so the mic button always fits.
                        final stageHeight =
                            (constraints.maxHeight -
                                    24 -
                                    _meterHeight -
                                    _minControlsHeight)
                                .clamp(260.0, 480.0);
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                24,
                                12,
                                24,
                                12,
                              ),
                              child: SizedBox(
                                width: double.infinity,
                                height: stageHeight,
                                child: _Stage(
                                  fill: _viewModel.fill,
                                  micLevel: _viewModel.micLevel,
                                  listening: _viewModel.listening,
                                ),
                              ),
                            ),
                            IntensityMeter(db: _viewModel.db),
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
                                      asset: 'assets/icons/ic_restart.svg',
                                      semanticLabel: 'Empty the tank',
                                      onPressed: _viewModel.restart,
                                    ),
                                    MicButton(
                                      listening: _viewModel.listening,
                                      level: _viewModel.micLevel,
                                      onPressed: _viewModel.canToggleMic
                                          ? _viewModel.toggleMic
                                          : null,
                                    ),
                                    CircleIconButton(
                                      asset: 'assets/icons/ic_check.svg',
                                      semanticLabel: 'Finish session',
                                      onPressed: _finishSession,
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

/// "Scream Tank" title in Sonsie One, shrunk to fit on narrow phones.
class ScreamTankWordmark extends StatelessWidget {
  const ScreamTankWordmark({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 66,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text('Scream Tank', maxLines: 1, style: AppText.wordmark),
      ),
    );
  }
}

class _Stage extends StatelessWidget {
  const _Stage({
    required this.fill,
    required this.micLevel,
    required this.listening,
  });

  final double fill;
  final double micLevel;
  final bool listening;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: ColoredBox(
        color: AppColors.text,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: TankIllustration(
                        fill: fill,
                        micLevel: micLevel,
                        listening: listening,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 270,
                    child: Text(
                      fill >= 1 ? 'Tank full! Well done.' : 'Let it all out!',
                      textAlign: TextAlign.center,
                      style: AppText.h3.copyWith(color: AppColors.background),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 16,
              top: 16,
              child: _ListeningPill(listening: listening),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListeningPill extends StatelessWidget {
  const _ListeningPill({required this.listening});

  final bool listening;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const ShapeDecoration(
        color: AppColors.background,
        shape: StadiumBorder(),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 14, 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: listening
                    ? AppColors.accent
                    : AppColors.text.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(listening ? 'Listening' : 'Paused', style: AppText.body),
          ],
        ),
      ),
    );
  }
}
