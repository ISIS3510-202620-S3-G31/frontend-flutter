import 'package:flutter/foundation.dart';

import '../../../../data/models/emotional_detective_model.dart';
import '../../../../data/repositories/emotional_detective_repository.dart';
import '../../../../data/services/analytics_service.dart';

export '../../../../data/models/emotional_detective_model.dart';

/// ViewModel managing state, question progression, and investigation summary
/// for the Emotional Detective feature.
class EmotionalDetectiveViewModel extends ChangeNotifier {
  EmotionalDetectiveViewModel({
    EmotionalDetectiveRepository? repository,
    AnalyticsService? analytics,
    EmotionalDetective? initialDetective,
    DetectiveStage initialStage = DetectiveStage.intro,
    int initialQuestionIndex = 0,
    this.customTrigger,
    this.customEmotion,
    this.customRecommendation,
    this.customRecommendedTool,
  }) : _repository = repository ?? const EmotionalDetectiveRepository(),
       _analytics = analytics ?? AnalyticsService(),
       _currentQuestionIndex = initialQuestionIndex {
    if (initialDetective != null) {
      _detective = initialDetective;
      final qIndex = _detective.questions.indexWhere(
        (q) => q.id == _detective.currentQuestion.id,
      );
      if (qIndex >= 0) {
        _currentQuestionIndex = qIndex;
      }
    } else {
      final loadedQuestions = _repository.getQuestions();
      final clampedIndex = loadedQuestions.isEmpty
          ? 0
          : _currentQuestionIndex.clamp(0, loadedQuestions.length - 1);
      _currentQuestionIndex = clampedIndex;

      final currentQ = loadedQuestions.isNotEmpty
          ? loadedQuestions[clampedIndex]
          : const Question(id: '0', text: '', options: []);

      _detective = EmotionalDetective(
        currentQuestion: currentQ,
        detectedTrigger: customTrigger ?? 'Fear of falling behind in deadlines',
        detectedEmotion: customEmotion, // Blank by default as requested
        questions: loadedQuestions,
        stage: initialStage,
        recommendation:
            customRecommendation ??
            'Take 2 minutes to try Custom Interval Breathing or leave a note in the Achievement Jar.',
        recommendedTool: customRecommendedTool ?? 'Custom Interval Breathing',
      );
    }
  }

  final EmotionalDetectiveRepository _repository;
  final AnalyticsService _analytics;
  late EmotionalDetective _detective;
  int _currentQuestionIndex;
  bool _isSaving = false;
  String? _errorMessage;

  final String? customTrigger;
  final String? customEmotion;
  final String? customRecommendation;
  final String? customRecommendedTool;

  EmotionalDetective get detective => _detective;
  DetectiveStage get stage => _detective.stage;
  bool get isCompleted => _detective.stage == DetectiveStage.summary;
  Question get currentQuestion => _detective.currentQuestion;
  int get currentQuestionIndex => _currentQuestionIndex;
  int get currentClueNumber => _currentQuestionIndex + 1;
  int get totalClues => _detective.questions.length;
  List<Question> get questions => List.unmodifiable(_detective.questions);
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  String? get selectedAnswer => _detective.currentQuestion.selectedAnswer;
  int? get selectedOption => _detective.currentQuestion.selectedOptionIndex;
  bool get canContinue => selectedAnswer != null;

  double get progress => _detective.questions.isEmpty
      ? 0.0
      : (_currentQuestionIndex + 1) / _detective.questions.length;

  String get detectedTrigger => _detective.detectedTrigger;
  String get triggerDiscovered => detectedTrigger;
  String? get detectedEmotion => _detective.detectedEmotion;

  String get rootEmotionIdentified {
    final emotion = _detective.detectedEmotion;
    if (emotion != null && emotion.isNotEmpty) {
      return emotion;
    }
    return 'Overwhelm & Anxiety';
  }

  String get recommendation => _detective.recommendation;
  String get recommendedTool => _detective.recommendedTool;

  void startInvestigation() {
    _detective = _detective.copyWith(stage: DetectiveStage.clues);
    _analytics.logToolStep(
      toolId: 'detective',
      stepName: 'clues_started',
      stepIndex: 0,
    );
    notifyListeners();
  }

  void selectAnswer(int optionIndex) {
    if (optionIndex < 0 || optionIndex >= currentQuestion.options.length) {
      return;
    }
    selectAnswerText(currentQuestion.options[optionIndex]);
  }

  void selectAnswerText(String answer) {
    final updatedQuestions = List<Question>.from(_detective.questions);
    final updatedQuestion = currentQuestion.copyWith(selectedAnswer: answer);
    updatedQuestions[_currentQuestionIndex] = updatedQuestion;

    _detective = _detective.copyWith(
      currentQuestion: updatedQuestion,
      questions: updatedQuestions,
      detectedTrigger: _resolveTrigger(updatedQuestions),
    );
    notifyListeners();
  }

  void continueInvestigation() {
    if (_currentQuestionIndex < _detective.questions.length - 1) {
      _currentQuestionIndex++;
      _detective = _detective.copyWith(
        currentQuestion: _detective.questions[_currentQuestionIndex],
      );
      _analytics.logToolStep(
        toolId: 'detective',
        stepName: 'clue_${_currentQuestionIndex + 1}',
        stepIndex: _currentQuestionIndex + 1,
      );
    } else {
      _detective = _detective.copyWith(stage: DetectiveStage.summary);
      _analytics.completeToolSession(
        toolId: 'detective',
        toolName: 'Emotional Detective',
      );
    }
    notifyListeners();
  }

  /// Handles back navigation. Returns `true` if handled internally within the
  /// detective flow, or `false` if the parent navigator should pop.
  bool handleBack() {
    switch (_detective.stage) {
      case DetectiveStage.intro:
        return false;
      case DetectiveStage.clues:
        if (_currentQuestionIndex > 0) {
          _currentQuestionIndex--;
          _detective = _detective.copyWith(
            currentQuestion: _detective.questions[_currentQuestionIndex],
          );
          notifyListeners();
          return true;
        } else {
          _detective = _detective.copyWith(stage: DetectiveStage.intro);
          notifyListeners();
          return true;
        }
      case DetectiveStage.summary:
        _detective = _detective.copyWith(stage: DetectiveStage.clues);
        notifyListeners();
        return true;
    }
  }

  void setStage(DetectiveStage stage) {
    if (_detective.stage != stage) {
      _detective = _detective.copyWith(stage: stage);
      notifyListeners();
    }
  }

  void setQuestionIndex(int index) {
    if (index >= 0 &&
        index < _detective.questions.length &&
        _currentQuestionIndex != index) {
      _currentQuestionIndex = index;
      _detective = _detective.copyWith(
        currentQuestion: _detective.questions[index],
      );
      notifyListeners();
    }
  }

  String _resolveTrigger(List<Question> questions) {
    if (customTrigger != null) return customTrigger!;
    final triggerQ = questions.firstWhere(
      (q) => q.id == 'trigger',
      orElse: () => questions.length > 1 ? questions[1] : questions.first,
    );

    switch (triggerQ.selectedOptionIndex) {
      case 0:
      case 1:
        return 'Fear of falling behind in deadlines';
      case 2:
        return 'Accumulated stress & mental overload';
      case 3:
        return 'Unexpected life challenge or event';
      default:
        return 'Fear of falling behind in deadlines';
    }
  }

  Future<bool> saveToInsights() async {
    _isSaving = true;
    notifyListeners();
    try {
      await _repository.saveInvestigation(_detective);
      _analytics.completeToolSession(
        toolId: 'detective',
        toolName: 'Emotional Detective',
      );
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (_) {
      _errorMessage = 'Could not save insights. Try again.';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
  }

  void reset() {
    final resetQuestions = _detective.questions.map((q) {
      return q.copyWith(selectedAnswer: null);
    }).toList();

    _currentQuestionIndex = 0;
    _detective = _detective.copyWith(
      stage: DetectiveStage.intro,
      currentQuestion: resetQuestions.isNotEmpty
          ? resetQuestions.first
          : const Question(id: '0', text: '', options: []),
      questions: resetQuestions,
      detectedEmotion: null,
    );
    _errorMessage = null;
    notifyListeners();
  }
}
