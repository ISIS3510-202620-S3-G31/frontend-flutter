import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/screen_header.dart';
import '../view_model/custom_breathing_view_model.dart';
import 'breathing_music_card.dart';
import 'duration_pills.dart';
import 'pattern_selector.dart';
import 'session_controls.dart';
import 'stepper_row.dart';
import 'timer_card.dart';

/// Breathing session with a rhythm countdown, pattern selector, steppers and session controls.
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final state = _viewModel.state;
        final steps = _viewModel.visibleSteps;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.dark,
          child: Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              child: Column(
                children: [
                  ScreenHeader(
                    title: Text(
                      'Custom breathing',
                      style: AppText.breathingTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: 'Build your own rhythm',
                    onBack: widget.onBack,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: PatternSelector(
                              selected: state.pattern,
                              onSelected: _viewModel.selectPattern,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: TimerCard(state: state),
                          ),
                          for (var i = 0; i < steps.length; i++)
                            Padding(
                              padding: EdgeInsets.only(top: i == 0 ? 0 : 10),
                              child: StepperRow(
                                label: steps[i].label,
                                seconds: state.secondsOf(steps[i]),
                                onDecrease: () =>
                                    _viewModel.changeStep(steps[i], -1),
                                onIncrease: () =>
                                    _viewModel.changeStep(steps[i], 1),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.only(top: 10, bottom: 8),
                            child: DurationPills(
                              selectedMinutes: state.sessionMinutes,
                              onSelected: _viewModel.selectDuration,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 16),
                            child: BreathingMusicCard(viewModel: _viewModel),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(40, 8, 40, 24),
                    child: SessionControls(
                      isRunning: state.isRunning,
                      onReset: _viewModel.resetSession,
                      onToggleRunning: _viewModel.toggleRunning,
                      onFinish: _finishSession,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
