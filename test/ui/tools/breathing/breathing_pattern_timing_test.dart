import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/data/models/breathing_model.dart';
import 'package:frontend_flutter/ui/tools/breathing/view_model/custom_breathing_view_model.dart';

void main() {
  group('Breathing Pattern Defaults and Customization', () {
    test('BreathingPattern default values match requirements', () {
      // 2-step must be symmetric by default
      expect(
        BreathingPattern.twoStep.defaultInhale,
        BreathingPattern.twoStep.defaultExhale,
      );

      // 3-step must have all 3 times the same by default
      expect(
        BreathingPattern.threeStep.defaultInhale,
        BreathingPattern.threeStep.defaultHold,
      );
      expect(
        BreathingPattern.threeStep.defaultHold,
        BreathingPattern.threeStep.defaultExhale,
      );

      // 4-7-8 must be 4, 7, 8 by default
      expect(BreathingPattern.fourSevenEight.defaultInhale, 4);
      expect(BreathingPattern.fourSevenEight.defaultHold, 7);
      expect(BreathingPattern.fourSevenEight.defaultExhale, 8);
    });

    test('Initial CustomBreathingState has all 3 times identical for threeStep', () {
      const state = CustomBreathingState();
      expect(state.pattern, BreathingPattern.threeStep);
      expect(state.inhaleSeconds, state.holdSeconds);
      expect(state.holdSeconds, state.exhaleSeconds);
      expect(state.inhaleSeconds, 4);
    });

    test('Selecting 2-step sets symmetric timings by default', () {
      final viewModel = CustomBreathingViewModel();

      viewModel.selectPattern(BreathingPattern.twoStep);
      expect(viewModel.state.pattern, BreathingPattern.twoStep);
      expect(viewModel.state.inhaleSeconds, viewModel.state.exhaleSeconds);
      expect(viewModel.state.inhaleSeconds, 4);
      expect(viewModel.state.exhaleSeconds, 4);

      viewModel.dispose();
    });

    test('Selecting 3-step sets all 3 times equal by default', () {
      final viewModel = CustomBreathingViewModel();

      // Switch to 4-7-8 then back to 3-step
      viewModel.selectPattern(BreathingPattern.fourSevenEight);
      expect(viewModel.state.inhaleSeconds, 4);
      expect(viewModel.state.holdSeconds, 7);
      expect(viewModel.state.exhaleSeconds, 8);

      viewModel.selectPattern(BreathingPattern.threeStep);
      expect(viewModel.state.pattern, BreathingPattern.threeStep);
      expect(viewModel.state.inhaleSeconds, 4);
      expect(viewModel.state.holdSeconds, 4);
      expect(viewModel.state.exhaleSeconds, 4);

      viewModel.dispose();
    });

    test('Selecting 4-7-8 sets 4-7-8 by default', () {
      final viewModel = CustomBreathingViewModel();

      viewModel.selectPattern(BreathingPattern.fourSevenEight);
      expect(viewModel.state.pattern, BreathingPattern.fourSevenEight);
      expect(viewModel.state.inhaleSeconds, 4);
      expect(viewModel.state.holdSeconds, 7);
      expect(viewModel.state.exhaleSeconds, 8);

      viewModel.dispose();
    });

    test('User customizations are remembered per pattern unless changed', () {
      final viewModel = CustomBreathingViewModel();

      // Customize 2-step: change inhale to 6
      viewModel.selectPattern(BreathingPattern.twoStep);
      viewModel.changeStep(BreathingStep.inhale, 2); // 4 + 2 = 6
      expect(viewModel.state.inhaleSeconds, 6);
      expect(viewModel.state.exhaleSeconds, 4);

      // Switch to 3-step (should have default 4-4-4)
      viewModel.selectPattern(BreathingPattern.threeStep);
      expect(viewModel.state.inhaleSeconds, 4);
      expect(viewModel.state.holdSeconds, 4);
      expect(viewModel.state.exhaleSeconds, 4);

      // Switch back to 2-step (should remember customized 6 and 4)
      viewModel.selectPattern(BreathingPattern.twoStep);
      expect(viewModel.state.inhaleSeconds, 6);
      expect(viewModel.state.exhaleSeconds, 4);

      // Switch to 4-7-8 (should have default 4-7-8)
      viewModel.selectPattern(BreathingPattern.fourSevenEight);
      expect(viewModel.state.inhaleSeconds, 4);
      expect(viewModel.state.holdSeconds, 7);
      expect(viewModel.state.exhaleSeconds, 8);

      viewModel.dispose();
    });
  });
}
