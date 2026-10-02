enum DetectiveStage { intro, clues, summary }

class Question {
  const Question({
    required this.id,
    required this.text,
    required this.options,
    this.selectedAnswer,
  });

  final String id;
  final String text;
  final List<String> options;
  final String? selectedAnswer;

  /// Returns the index of [selectedAnswer] in [options], or null if not selected.
  int? get selectedOptionIndex {
    final answer = selectedAnswer;
    if (answer == null) return null;
    final index = options.indexOf(answer);
    return index >= 0 ? index : null;
  }

  Question copyWith({
    String? id,
    String? text,
    List<String>? options,
    String? selectedAnswer,
  }) {
    return Question(
      id: id ?? this.id,
      text: text ?? this.text,
      options: options ?? this.options,
      selectedAnswer: selectedAnswer ?? this.selectedAnswer,
    );
  }
}

/// Root domain model representing an Emotional Detective investigation.
class EmotionalDetective {
  const EmotionalDetective({
    required this.currentQuestion,
    this.detectedTrigger = 'Fear of falling behind in deadlines',
    this.detectedEmotion,
    this.questions = const [],
    this.stage = DetectiveStage.intro,
    this.recommendation =
        'Take 2 minutes to try Custom Interval Breathing or leave a note in the Achievement Jar.',
    this.recommendedTool = 'Custom Interval Breathing',
  });

  final Question currentQuestion;
  final String detectedTrigger;
  final String? detectedEmotion;
  final List<Question> questions;
  final DetectiveStage stage;
  final String recommendation;
  final String recommendedTool;

  EmotionalDetective copyWith({
    Question? currentQuestion,
    String? detectedTrigger,
    String? detectedEmotion,
    List<Question>? questions,
    DetectiveStage? stage,
    String? recommendation,
    String? recommendedTool,
  }) {
    return EmotionalDetective(
      currentQuestion: currentQuestion ?? this.currentQuestion,
      detectedTrigger: detectedTrigger ?? this.detectedTrigger,
      detectedEmotion: detectedEmotion ?? this.detectedEmotion,
      questions: questions ?? this.questions,
      stage: stage ?? this.stage,
      recommendation: recommendation ?? this.recommendation,
      recommendedTool: recommendedTool ?? this.recommendedTool,
    );
  }
}
