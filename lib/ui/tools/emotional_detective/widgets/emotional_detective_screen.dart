import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/circle_icon_button.dart';
import '../view_model/emotional_detective_view_model.dart';

/// Emotional Detective screen where "Sprout Detective" guides the user through
/// identifying emotional triggers, root feelings, and actionable recommendations.
class EmotionalDetectiveScreen extends StatefulWidget {
  const EmotionalDetectiveScreen({super.key, this.viewModel});

  /// Pass one in tests; otherwise the screen builds and disposes its own.
  final EmotionalDetectiveViewModel? viewModel;

  @override
  State<EmotionalDetectiveScreen> createState() =>
      _EmotionalDetectiveScreenState();
}

class _EmotionalDetectiveScreenState extends State<EmotionalDetectiveScreen> {
  late final EmotionalDetectiveViewModel _viewModel =
      widget.viewModel ?? EmotionalDetectiveViewModel();
  late final bool _ownsViewModel = widget.viewModel == null;

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(_onViewModelChanged);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    if (_ownsViewModel) _viewModel.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    final message = _viewModel.errorMessage;
    if (message == null || !mounted) return;
    _viewModel.clearError();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Cream background color for cards and panels.
  static const _panelColor = Color(0xFFFDF3E0);

  ButtonStyle get _primaryButtonStyle => FilledButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.text,
    minimumSize: const Size.fromHeight(56),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: const BorderSide(color: AppColors.text, width: 2),
    ),
    elevation: 4,
    shadowColor: AppColors.text,
    textStyle: AppText.h3.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
  );

  void _onBack() {
    if (!_viewModel.handleBack()) {
      Navigator.maybePop(context, _viewModel.isCompleted);
    }
  }

  Widget _buildBackButton() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.text, width: 1.5),
      ),
      child: CircleIconButton(
        asset: 'assets/icons/ic_chevron_left.svg',
        semanticLabel: 'Back',
        background: Colors.transparent,
        size: 42,
        iconSize: 20,
        onPressed: _onBack,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: switch (_viewModel.stage) {
              DetectiveStage.intro => _buildIntroView(),
              DetectiveStage.clues => _buildCluesView(),
              DetectiveStage.summary => _buildSummaryView(),
            },
          ),
        );
      },
    );
  }

  Widget _buildIntroView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        children: [
          Align(alignment: Alignment.centerLeft, child: _buildBackButton()),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Text(
                    'Meet Sprout Detective!',
                    style: AppText.h1.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  Image.asset(
                    'assets/illustrations/sprout_detective.png',
                    height: 190,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 32),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: _panelColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.text.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      'Hi there! I\'m Sprout Detective. Let\'s explore your feelings together and solve the case of what\'s on your mind.\n\nReady to investigate?',
                      style: AppText.body.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.45,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _viewModel.startInvestigation,
            style: _primaryButtonStyle,
            child: const Text('Let\'s Investigate!'),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildCluesView() {
    final question = _viewModel.currentQuestion;
    final selectedOption = _viewModel.selectedOption;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header row with back button, title, and clue counter
          Row(
            children: [
              _buildBackButton(),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Emotional Detective',
                  style: AppText.h2.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                'Clue ${_viewModel.currentClueNumber} of ${_viewModel.totalClues}',
                style: AppText.body.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _viewModel.progress,
              minHeight: 6,
              backgroundColor: AppColors.text.withValues(alpha: 0.12),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.secondary,
              ),
            ),
          ),
          const SizedBox(height: 20),

          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: BoxDecoration(
                color: _panelColor,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.text.withValues(alpha: 0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.search_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    question.text,
                    style: AppText.h3.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.25,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  Expanded(
                    child: ListView.separated(
                      itemCount: question.options.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final isSelected = selectedOption == index;
                        final optionText = question.options[index];

                        return InkWell(
                          onTap: () => _viewModel.selectAnswer(index),
                          borderRadius: BorderRadius.circular(16),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFE0F4F2)
                                  : _panelColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.secondary
                                    : const Color(0xFFE8DCC8),
                                width: isSelected ? 2 : 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.text.withValues(alpha: 0.04),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Custom radio circle
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.secondary
                                          : const Color(0xFFC7BBAA),
                                      width: 2,
                                    ),
                                  ),
                                  child: isSelected
                                      ? Center(
                                          child: Container(
                                            width: 10,
                                            height: 10,
                                            decoration: const BoxDecoration(
                                              color: AppColors.secondary,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    optionText,
                                    style: AppText.body.copyWith(
                                      fontWeight: FontWeight.w600,
                                      height: 1.25,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Bottom action button
          FilledButton(
            onPressed:
                _viewModel.canContinue ? _viewModel.continueInvestigation : null,
            style: _primaryButtonStyle,
            child: const Text('Continue Investigation'),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildSummaryView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        children: [
          // Header row with back button and title
          Row(
            children: [
              _buildBackButton(),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Investigation Summary',
                  style: AppText.h2.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Text(
                    '✨ Case Solved! ✨',
                    style: AppText.h2.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),

                  // Detective character illustration
                  Image.asset(
                    'assets/illustrations/sprout_detective.png',
                    height: 110,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 18),

                  // Summary breakdown card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: _panelColor,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.text.withValues(alpha: 0.06),
                          blurRadius: 18,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummarySection(
                          label: 'TRIGGER DISCOVERED',
                          content: _viewModel.triggerDiscovered,
                          isBold: true,
                        ),
                        const Divider(
                          color: Color(0xFFEFE5D5),
                          height: 32,
                          thickness: 1,
                        ),
                        _buildSummarySection(
                          label: 'ROOT EMOTION IDENTIFIED',
                          content: _viewModel.rootEmotionIdentified,
                          isBold: true,
                        ),
                        const Divider(
                          color: Color(0xFFEFE5D5),
                          height: 32,
                          thickness: 1,
                        ),
                        _buildSummarySection(
                          label: 'RECOMMENDATION',
                          content: _viewModel.recommendation,
                          isBold: false,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Primary action
          FilledButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Opening ${_viewModel.recommendedTool}...'),
                ),
              );
            },
            style: _primaryButtonStyle,
            child: const Text('Go to Recommended Tool'),
          ),
          const SizedBox(height: 8),

          // Secondary action
          TextButton(
            onPressed: () async {
              await _viewModel.saveToInsights();
              if (mounted) {
                Navigator.maybePop(context, true);
              }
            },
            child: Text(
              'Save to My Insights & Finish',
              style: AppText.body.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSummarySection({
    required String label,
    required String content,
    required bool isBold,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppText.body.copyWith(
            color: AppColors.secondary,
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: AppText.body.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}
