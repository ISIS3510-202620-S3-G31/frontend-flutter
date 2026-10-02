import '../models/emotional_detective_model.dart';

class EmotionalDetectiveRepository {
  const EmotionalDetectiveRepository();

  List<Question> getQuestions() => const [
    Question(
      id: 'feeling',
      text: 'What feeling is most present for you right now?',
      options: [
        'I feel anxious or on edge',
        'I feel overwhelmed with everything',
        'I feel drained and low on energy',
        'Something else is happening...',
      ],
    ),
    Question(
      id: 'trigger',
      text: 'What happened right before you felt overwhelmed?',
      options: [
        'A tough test or deadline at school/work',
        'An argument or misunderstanding with a friend',
        'Too many small things piled up',
        'Something else happened...',
      ],
    ),
    Question(
      id: 'body',
      text: 'Where do you notice this tension in your body?',
      options: [
        'In my shoulders, jaw, or neck',
        'In my chest or shallow breathing',
        'In my stomach or headache',
        'I feel mostly numb or disconnected',
      ],
    ),
    Question(
      id: 'thought',
      text: 'What thought keeps looping in your head?',
      options: [
        'I won\'t be able to get everything done',
        'I feel like I let someone down',
        'Everything is just too much right now',
        'I need to step back and breathe',
      ],
    ),
  ];

  Future<void> saveInvestigation(EmotionalDetective detective) async {
    // Insights persistence can be hooked up here (e.g. local database / secure storage).
  }
}
