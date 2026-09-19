import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:noise_meter/noise_meter.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/circle_icon_button.dart';
import '../../widgets/screen_header.dart';
import 'intensity_meter.dart';
import 'mic_button.dart';
import 'tank_illustration.dart';

/// The user screams into the phone: the mic level drives the intensity meter,
/// and loudness accumulated over time fills the tank.
class ScreamTankScreen extends StatefulWidget {
  const ScreamTankScreen({super.key});

  @override
  State<ScreamTankScreen> createState() => _ScreamTankScreenState();
}

class _ScreamTankScreenState extends State<ScreamTankScreen>
    with WidgetsBindingObserver {
  /// Room for the 116 px mic button plus some breathing space.
  static const _minControlsHeight = 140.0;
  static const _meterHeight = 75.0;

  /// Seconds of screaming at full level needed to fill the tank.
  static const _secondsToFill = 20.0;

  /// Quieter readings don't fill the tank, so silence doesn't count.
  static const _fillThresholdDb = 60.0;

  /// How fast the meter follows the mic, so it doesn't flicker.
  static const _smoothingSeconds = 0.15;

  StreamSubscription<NoiseReading>? _noise;
  bool _requestingMic = false;
  DateTime? _lastReading;
  double _db = 0;
  double _fill = 0;

  bool get _listening => _noise != null;
  bool get _full => _fill >= 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _noise?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _stopListening();
  }

  Future<void> _startListening() async {
    if (_listening || _requestingMic || _full) return;
    setState(() => _requestingMic = true);
    final status = await Permission.microphone.request();
    if (!mounted) return;
    setState(() => _requestingMic = false);

    if (!status.isGranted) {
      _showMessage(
        'Scream Tank needs the microphone to hear you.',
        openSettings: status.isPermanentlyDenied,
      );
      return;
    }

    _lastReading = null;
    setState(() {
      _noise = NoiseMeter().noise.listen(
        _onReading,
        onError: (Object _) {
          _stopListening();
          _showMessage('The microphone stopped working.');
        },
      );
    });
  }

  void _onReading(NoiseReading reading) {
    final db = reading.meanDecibel;
    if (!db.isFinite) return; // a completely silent buffer gives -infinity

    final now = DateTime.now();
    final last = _lastReading;
    _lastReading = now;
    // Seconds since the previous reading, capped so a hiccup can't jump ahead.
    final dt = last == null
        ? 0.0
        : math.min(now.difference(last).inMicroseconds / 1e6, 0.5);

    setState(() {
      final smoothing = dt == 0 ? 1.0 : 1 - math.exp(-dt / _smoothingSeconds);
      _db += (db - _db) * smoothing;
      if (_db >= _fillThresholdDb) {
        _fill = math.min(1.0, _fill + levelFromDb(_db) * dt / _secondsToFill);
      }
    });

    if (_full) {
      HapticFeedback.heavyImpact();
      _stopListening();
    }
  }

  void _stopListening() {
    final noise = _noise;
    if (noise == null) return;
    noise.cancel();
    setState(() {
      _noise = null;
      _db = 0;
    });
  }

  void _toggleMic() => _listening ? _stopListening() : _startListening();

  void _restart() {
    _stopListening();
    setState(() => _fill = 0);
  }

  void _done() {
    _stopListening();
    Navigator.maybePop(context);
  }

  void _showMessage(String message, {bool openSettings = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: openSettings
            ? SnackBarAction(label: 'Settings', onPressed: openAppSettings)
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final level = levelFromDb(_db);

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
                    // 480 px on the 844 px Figma frame; shorter phones get a
                    // shorter stage so the mic button always fits.
                    final stageHeight =
                        (constraints.maxHeight -
                                24 -
                                _meterHeight -
                                _minControlsHeight)
                            .clamp(260.0, 480.0);
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                          child: SizedBox(
                            width: double.infinity,
                            height: stageHeight,
                            child: _Stage(
                              fill: _fill,
                              micLevel: level,
                              listening: _listening,
                            ),
                          ),
                        ),
                        IntensityMeter(db: _db),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                CircleIconButton(
                                  asset: 'assets/icons/ic_restart.svg',
                                  semanticLabel: 'Empty the tank',
                                  onPressed: _restart,
                                ),
                                MicButton(
                                  listening: _listening,
                                  level: level,
                                  onPressed: _requestingMic || _full
                                      ? null
                                      : _toggleMic,
                                ),
                                CircleIconButton(
                                  asset: 'assets/icons/ic_check.svg',
                                  semanticLabel: 'Finish session',
                                  onPressed: _done,
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

/// Dark card with the tank illustration and the Listening / Paused pill.
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
