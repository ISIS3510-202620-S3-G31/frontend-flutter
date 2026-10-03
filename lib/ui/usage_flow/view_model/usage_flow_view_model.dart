import 'package:flutter/foundation.dart';

import '../../../data/models/tool_model.dart';
import '../../../domain/usage_flow/flow_group.dart';
import '../../../domain/usage_flow/flow_step.dart';
import '../../../domain/usage_flow/usage_flow_template.dart';

/// Walks the user through the usage flow of one tool, one step at a time.
class UsageFlowViewModel extends ChangeNotifier {
  UsageFlowViewModel({required ToolItem tool})
    : flow = UsageFlowTemplate.forTool(tool);

  final FlowGroup flow;
  late final List<SingleStep> _steps = flow.steps;
  late final List<MoodCheckStep> _moodChecks = _steps
      .whereType<MoodCheckStep>()
      .toList();

  /// The first step not done yet, or null when the flow is over.
  SingleStep? get currentStep =>
      _steps.where((step) => !step.isComplete).firstOrNull;

  bool get isFinished => flow.isComplete;

  int get stepCount => _steps.length;

  int get doneCount => _steps.where((step) => step.isComplete).length;

  /// Title of the part the current step belongs to, like "Before the tool".
  String get partTitle {
    final step = currentStep;
    if (step == null) return 'All done';
    return flow.children.firstWhere((part) => part.steps.contains(step)).title;
  }

  int? get intensityBefore => _moodChecks.first.intensity;
  int? get intensityAfter => _moodChecks.last.intensity;
  Usefulness? get usefulness => _steps.whereType<RatingStep>().first.answer;

  String get summary {
    final before = intensityBefore;
    final after = intensityAfter;
    if (before == null || after == null) return '';
    if (after < before) return 'You feel lighter than when you started.';
    if (after == before) return 'Same as before, and that is okay.';
    return 'Thanks for being honest. Another tool might fit better next time.';
  }

  void chooseIntensity(int intensity) {
    final step = currentStep;
    if (step is! MoodCheckStep) return;
    step.intensity = intensity;
    notifyListeners();
  }

  void finishTool() {
    final step = currentStep;
    if (step is! ToolStep) return;
    step.finished = true;
    notifyListeners();
  }

  void rate(Usefulness answer) {
    final step = currentStep;
    if (step is! RatingStep) return;
    step.answer = answer;
    notifyListeners();
  }
}
