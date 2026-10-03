import 'package:flutter/foundation.dart';

import '../../../data/models/tool_feedback_model.dart';
import '../../../data/repositories/feedback_repository.dart';

class ToolFeedbackViewModel extends ChangeNotifier {
  ToolFeedbackViewModel({
    required this.toolId,
    required this.startedAt,
    required this.durationSeconds,
    FeedbackRepository? repository,
  }) : _repository = repository ?? FeedbackRepository();

  static const maxCommentLength = 160;

  final String toolId;
  final DateTime startedAt;
  final int durationSeconds;
  final FeedbackRepository _repository;

  int _rating = 5;
  FeedbackMood? _mood;
  final Set<FeedbackTag> _tags = {};
  String _comment = '';
  bool _favorite = false;
  bool _saving = false;
  bool _saved = false;
  String? _message;
  bool _disposed = false;

  int get rating => _rating;
  FeedbackMood? get mood => _mood;
  Set<FeedbackTag> get tags => _tags;
  String get comment => _comment;
  bool get favorite => _favorite;
  bool get saving => _saving;

  /// True once the feedback is stored, so the screen can close itself.
  bool get saved => _saved;

  /// Message to show once in a snack bar. The screen calls [clearMessage].
  String? get message => _message;

  /// The mood is the only answer the stats screen cannot do without.
  bool get canSave => _mood != null && !_saving;

  /// Short description of the rating, shown next to the number.
  String get ratingLabel => switch (_rating) {
    <= 2 => 'Hard to use',
    <= 4 => 'Could be better',
    5 => 'Neutral',
    <= 7 => 'Does its job',
    <= 9 => 'Smooth and clear',
    _ => 'Exceptional',
  };

  void setRating(int value) {
    _rating = value.clamp(1, 10);
    notifyListeners();
  }

  void selectMood(FeedbackMood mood) {
    _mood = mood;
    notifyListeners();
  }

  void toggleTag(FeedbackTag tag) {
    _tags.contains(tag) ? _tags.remove(tag) : _tags.add(tag);
    notifyListeners();
  }

  void setComment(String value) {
    _comment = value;
    notifyListeners();
  }

  void toggleFavorite() {
    _favorite = !_favorite;
    notifyListeners();
  }

  Future<void> save() async {
    final mood = _mood;
    if (mood == null || _saving) return;
    _saving = true;
    _notify();
    try {
      await _repository.save(
        ToolFeedback(
          toolId: toolId,
          rating: _rating,
          mood: mood,
          startedAt: startedAt,
          durationSeconds: durationSeconds,
          tags: _tags.toList(),
          comment: _comment.trim(),
          favorite: _favorite,
        ),
      );
      _saved = true;
      _message = 'Thanks! Your feedback is saved.';
    } on Exception {
      _message = 'Could not save your feedback. Check your connection.';
    } finally {
      _saving = false;
      _notify();
    }
  }

  void clearMessage() => _message = null;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
