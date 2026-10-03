import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/models/tool_model.dart';
import '../../../domain/usage_flow/flow_step.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/screen_header.dart';
import '../../feedback/widgets/tool_feedback_screen.dart';
import '../view_model/usage_flow_view_model.dart';
import 'action_step_view.dart';
import 'flow_progress.dart';
import 'flow_summary.dart';
import 'question_view.dart';


class UsageFlowScreen extends StatefulWidget {
  const UsageFlowScreen({
    super.key,
    required this.tool,
    required this.toolScreen,
    this.viewModel,
  });

  final ToolItem tool;
  final WidgetBuilder toolScreen;

  /// Pass one in tests; otherwise the screen builds and disposes its own.
  final UsageFlowViewModel? viewModel;

  @override
  State<UsageFlowScreen> createState() => _UsageFlowScreenState();
}

class _UsageFlowScreenState extends State<UsageFlowScreen> {
  late final UsageFlowViewModel _viewModel =
      widget.viewModel ?? UsageFlowViewModel(tool: widget.tool);
  late final bool _ownsViewModel = widget.viewModel == null;

  @override
  void dispose() {
    if (_ownsViewModel) _viewModel.dispose();
    super.dispose();
  }

  Future<void> _openTool() async {
    _viewModel.startTool();
    await Navigator.push(
      context,
      MaterialPageRoute(builder: widget.toolScreen),
    );
    if (!mounted) return;
    _viewModel.finishTool();
  }

  Future<void> _openFeedback() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ToolFeedbackScreen(
          toolId: widget.tool.id,
          toolName: widget.tool.title,
          startedAt: _viewModel.toolStartedAt,
          durationSeconds: _viewModel.toolSeconds,
        ),
      ),
    );
    if (!mounted) return;
    _viewModel.finishFeedback();
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
              child: Column(
                children: [
                  ScreenHeader(
                    title: Text(
                      widget.tool.title,
                      style: AppText.h1,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: _viewModel.partTitle,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                    child: FlowProgress(
                      done: _viewModel.doneCount,
                      total: _viewModel.stepCount,
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                      child: _currentStepView(),
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

  Widget _currentStepView() => switch (_viewModel.currentStep) {
    MoodCheckStep step => QuestionView(
      question: step.title,
      hint: '1 is calm, 5 is very strong.',
      options: const ['1', '2', '3', '4', '5'],
      onSelected: (index) => _viewModel.chooseIntensity(index + 1),
    ),
    ToolStep step => ActionStepView(
      title: 'Time for the tool',
      message: 'When you finish, come back here to see how you feel.',
      tool: step.tool,
      buttonLabel: 'Start',
      onPressed: _openTool,
    ),
    FeedbackStep() => ActionStepView(
      title: 'One last thing',
      message: 'Tell us how the tool felt to use.',
      tool: widget.tool,
      buttonLabel: 'Give feedback',
      onPressed: _openFeedback,
    ),
    null => FlowSummary(
      before: _viewModel.intensityBefore!,
      after: _viewModel.intensityAfter!,
      message: _viewModel.summary,
      onDone: () => Navigator.pop(context),
    ),
  };
}
