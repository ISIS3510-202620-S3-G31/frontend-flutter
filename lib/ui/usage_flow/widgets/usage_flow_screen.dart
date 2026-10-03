import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/models/tool_model.dart';
import '../../../domain/usage_flow/flow_step.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/screen_header.dart';
import '../view_model/usage_flow_view_model.dart';
import 'flow_progress.dart';
import 'flow_summary.dart';
import 'question_view.dart';
import 'tool_step_view.dart';

/// Wraps a tool with a mood check before it and a check and rating after it.
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
    await Navigator.push(
      context,
      MaterialPageRoute(builder: widget.toolScreen),
    );
    if (!mounted) return;
    _viewModel.finishTool();
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
    ToolStep step => ToolStepView(tool: step.tool, onStart: _openTool),
    RatingStep step => QuestionView(
      question: step.title,
      options: [for (final answer in Usefulness.values) answer.label],
      onSelected: (index) => _viewModel.rate(Usefulness.values[index]),
    ),
    null => FlowSummary(
      before: _viewModel.intensityBefore!,
      after: _viewModel.intensityAfter!,
      usefulness: _viewModel.usefulness!,
      message: _viewModel.summary,
      onDone: () => Navigator.pop(context),
    ),
  };
}
