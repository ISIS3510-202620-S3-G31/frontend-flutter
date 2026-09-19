import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/circle_icon_button.dart';

/// The 3 distinct stages of the Sprout Detective flow.
enum _DetectiveStage { intro, clues, summary }

/// Data representation for an investigation clue question.
class _Clue {
  const _Clue({required this.question, required this.options});

  final String question;
  final List<String> options;
}

/// Emotional Detective screen where "Sprout Detective" guides the user through
/// identifying emotional triggers, root feelings, and actionable recommendations.
class EmotionalDetectiveScreen extends StatefulWidget {
  const EmotionalDetectiveScreen({super.key});

  @override
  State<EmotionalDetectiveScreen> createState() =>
      _EmotionalDetectiveScreenState();
}

class _EmotionalDetectiveScreenState extends State<EmotionalDetectiveScreen> {
  _DetectiveStage _stage = _DetectiveStage.intro;
  int _currentClueIndex = 1; // Default to Clue 2 (index 1)
  final Map<int, int> _selectedAnswers = {1: 1};

  static const List<_Clue> _clues = [
    _Clue(
      question: 'What feeling is most present for you right now?',
      options: [
        'I feel anxious or on edge',
        'I feel overwhelmed with everything',
        'I feel drained and low on energy',
        'Something else is happening...',
      ],
    ),
    _Clue(
      question: 'What happened right before you felt overwhelmed?',
      options: [
        'A tough test or deadline at school/work',
        'An argument or misunderstanding with a friend',
        'Too many small things piled up',
        'Something else happened...',
      ],
    ),
    _Clue(
      question: 'Where do you notice this tension in your body?',
      options: [
        'In my shoulders, jaw, or neck',
        'In my chest or shallow breathing',
        'In my stomach or headache',
        'I feel mostly numb or disconnected',
      ],
    ),
    _Clue(
      question: 'What thought keeps looping in your head?',
      options: [
        'I won\'t be able to get everything done',
        'I feel like I let someone down',
        'Everything is just too much right now',
        'I need to step back and breathe',
      ],
    ),
  ];

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
    switch (_stage) {
      case _DetectiveStage.intro:
        Navigator.maybePop(context);
      case _DetectiveStage.clues:
        if (_currentClueIndex > 0) {
          setState(() => _currentClueIndex--);
        } else {
          setState(() => _stage = _DetectiveStage.intro);
        }
      case _DetectiveStage.summary:
        setState(() => _stage = _DetectiveStage.clues);
    }
  }

  void _onContinueClue() {
    if (_currentClueIndex < _clues.length - 1) {
      setState(() => _currentClueIndex++);
    } else {
      setState(() => _stage = _DetectiveStage.summary);
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: switch (_stage) {
          _DetectiveStage.intro => _buildIntroView(),
          _DetectiveStage.clues => _buildCluesView(),
          _DetectiveStage.summary => _buildSummaryView(),
        },
      ),
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
            onPressed: () => setState(() => _stage = _DetectiveStage.clues),
            style: _primaryButtonStyle,
            child: const Text('Let\'s Investigate!'),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildCluesView() {
    final clue = _clues[_currentClueIndex];
    final selectedOption = _selectedAnswers[_currentClueIndex];
    final progress = (_currentClueIndex + 1) / _clues.length;

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
                'Clue ${_currentClueIndex + 1} of ${_clues.length}',
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
              value: progress,
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
                    clue.question,
                    style: AppText.h3.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.25,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  Expanded(
                    child: ListView.separated(
                      itemCount: clue.options.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final isSelected = selectedOption == index;
                        final optionText = clue.options[index];

                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedAnswers[_currentClueIndex] = index;
                            });
                          },
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
            onPressed: selectedOption != null ? _onContinueClue : null,
            style: _primaryButtonStyle,
            child: const Text('Continue Investigation'),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // View 3: Investigation Summary
  // ---------------------------------------------------------------------------
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
                          content: 'Fear of falling behind in deadlines',
                          isBold: true,
                        ),
                        const Divider(
                          color: Color(0xFFEFE5D5),
                          height: 32,
                          thickness: 1,
                        ),
                        _buildSummarySection(
                          label: 'ROOT EMOTION IDENTIFIED',
                          content: 'Overwhelm & Anxiety',
                          isBold: true,
                        ),
                        const Divider(
                          color: Color(0xFFEFE5D5),
                          height: 32,
                          thickness: 1,
                        ),
                        _buildSummarySection(
                          label: 'RECOMMENDATION',
                          content:
                              'Take 2 minutes to try Custom Interval Breathing or leave a note in the Achievement Jar.',
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
                const SnackBar(
                  content: Text('Opening Custom Interval Breathing...'),
                ),
              );
            },
            style: _primaryButtonStyle,
            child: const Text('Go to Recommended Tool'),
          ),
          const SizedBox(height: 8),

          // Secondary action
          TextButton(
            onPressed: () => Navigator.maybePop(context),
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
