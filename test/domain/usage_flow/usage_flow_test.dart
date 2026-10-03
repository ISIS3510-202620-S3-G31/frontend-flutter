import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/data/models/tool_model.dart';
import 'package:frontend_flutter/domain/usage_flow/flow_group.dart';
import 'package:frontend_flutter/domain/usage_flow/flow_step.dart';
import 'package:frontend_flutter/domain/usage_flow/usage_flow_template.dart';
import 'package:frontend_flutter/ui/usage_flow/view_model/usage_flow_view_model.dart';

const _tool = ToolItem(
  id: 'breathing',
  title: 'Breathing',
  description: 'Slow down your breath',
  iconAsset: 'assets/icons/ic_breathing.svg',
  category: ToolCategory.calmDown,
);

void main() {
  group('Composite', () {
    test('a group collects the steps of its children in order', () {
      final first = MoodCheckStep('a');
      final second = RatingStep('b');
      final third = MoodCheckStep('c');
      final root = FlowGroup('root')
        ..add(first)
        ..add(FlowGroup('nested')..add(second)..add(third));

      expect(root.steps, [first, second, third]);
    });

    test('a group is complete only when every child is', () {
      final mood = MoodCheckStep('a');
      final rating = RatingStep('b');
      final root = FlowGroup('root')
        ..add(mood)
        ..add(FlowGroup('nested')..add(rating));

      expect(root.isComplete, isFalse);
      mood.intensity = 3;
      expect(root.isComplete, isFalse);
      rating.answer = Usefulness.aLot;
      expect(root.isComplete, isTrue);
    });

    test('the template wraps the tool with checks before and after', () {
      final flow = UsageFlowTemplate.forTool(_tool);

      expect(flow.children.map((part) => part.title), [
        'Before the tool',
        'Breathing',
        'After the tool',
      ]);
      expect(flow.steps.map((step) => step.runtimeType), [
        MoodCheckStep,
        ToolStep,
        MoodCheckStep,
        RatingStep,
      ]);
    });
  });

  group('UsageFlowViewModel', () {
    test('walks every step and ends with a summary', () {
      final viewModel = UsageFlowViewModel(tool: _tool);

      expect(viewModel.currentStep, isA<MoodCheckStep>());
      expect(viewModel.partTitle, 'Before the tool');
      viewModel.chooseIntensity(4);

      expect(viewModel.currentStep, isA<ToolStep>());
      viewModel.finishTool();

      expect(viewModel.partTitle, 'After the tool');
      viewModel.chooseIntensity(2);
      expect(viewModel.currentStep, isA<RatingStep>());
      viewModel.rate(Usefulness.aLot);

      expect(viewModel.isFinished, isTrue);
      expect(viewModel.currentStep, isNull);
      expect(viewModel.doneCount, viewModel.stepCount);
      expect(viewModel.intensityBefore, 4);
      expect(viewModel.intensityAfter, 2);
      expect(viewModel.summary, 'You feel lighter than when you started.');
    });

    test('ignores answers that do not match the current step', () {
      final viewModel = UsageFlowViewModel(tool: _tool);

      viewModel.rate(Usefulness.aLot);
      viewModel.finishTool();

      expect(viewModel.doneCount, 0);
      expect(viewModel.currentStep, isA<MoodCheckStep>());
    });
  });
}
