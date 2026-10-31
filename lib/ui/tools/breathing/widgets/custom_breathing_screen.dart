import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../data/models/breathing_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/screen_header.dart';
import '../view_model/custom_breathing_view_model.dart';
import 'breathing_circle.dart';
import 'breathing_music_sheet.dart';
import 'breathing_round_button.dart';
import 'duration_pills.dart';
import 'pattern_selector.dart';
import 'session_controls.dart';

class CustomBreathingScreen extends StatefulWidget {
  const CustomBreathingScreen({super.key, this.viewModel, this.onBack});

  final CustomBreathingViewModel? viewModel;
  final VoidCallback? onBack;

  @override
  State<CustomBreathingScreen> createState() => _CustomBreathingScreenState();
}

class _CustomBreathingScreenState extends State<CustomBreathingScreen> {
  late final CustomBreathingViewModel _viewModel =
      widget.viewModel ?? CustomBreathingViewModel();
  late final bool _ownsViewModel = widget.viewModel == null;

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(_onViewModelChanged);
    _viewModel.start();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    if (_ownsViewModel) _viewModel.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    final message = _viewModel.message;
    if (message == null || !mounted) return;
    _viewModel.clearMessage();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _finishSession() {
    _viewModel.stop();
    Navigator.maybePop(context, _viewModel.isCompleted);
  }

  /// After the last cycle, play starts a new session from the beginning.
  void _toggleRunning() {
    if (_viewModel.isCompleted) _viewModel.resetSession();
    _viewModel.toggleRunning();
  }

  /// The tracks sheet made by the team (Jamendo, cache, preview, download).
  void _openMusic() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BreathingMusicSheet(viewModel: _viewModel),
    ).whenComplete(() {
      _viewModel.stopPreview();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final state = _viewModel.state;
        final isReady = _viewModel.isReady;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.dark,
          child: Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              child: Column(
                children: [
                  ScreenHeader(
                    title: Text(
                      'Custom Breathing',
                      style: AppText.h1,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onBack: widget.onBack,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                      height: 48,
                      child: Row(
                        children: [
                          Expanded(
                            child: Center(
                              child: isReady
                                  ? PatternSelector(
                                      selected: state.pattern,
                                      onSelected: _viewModel.selectPattern,
                                    )
                                  : _CyclesText(
                                      count: _viewModel.completedCycles,
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _MusicButton(state: state, onPressed: _openMusic),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      // On short phones everything shrinks instead of overflowing.
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            BreathingCircle(
                              state: state,
                              isReady: isReady,
                              isCompleted: _viewModel.isCompleted,
                            ),
                            if (isReady) ...[
                              const SizedBox(height: 24),
                              DurationPills(
                                selectedMinutes: state.sessionMinutes,
                                onSelected: _viewModel.selectDuration,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  SessionControls(
                    isRunning: state.isRunning,
                    isReady: isReady,
                    canReset: _viewModel.canReset,
                    onReset: _viewModel.resetSession,
                    onToggleRunning: _toggleRunning,
                    onFinish: _finishSession,
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

/// "N cycles" from the first finished cycle; nothing before it.
class _CyclesText extends StatelessWidget {
  const _CyclesText({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    return Text(count == 1 ? '1 cycle' : '$count cycles', style: AppText.h3);
  }
}


class _MusicButton extends StatelessWidget {
  const _MusicButton({required this.state, required this.onPressed});

  final CustomBreathingState state;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final playing =
        state.isMusicEnabled && state.isRunning && state.selectedTrack != null;

    return BreathingRoundButton(
      filled: playing,
      icon: Icon(
        playing
            ? Icons.graphic_eq
            : state.isMusicEnabled
            ? Icons.music_note
            : Icons.music_off,
        color: AppColors.text,
        size: 22,
      ),
      semanticLabel: playing
          ? 'Ambient music playing, choose track'
          : 'Ambient music',
      onPressed: onPressed,
    );
  }
}
