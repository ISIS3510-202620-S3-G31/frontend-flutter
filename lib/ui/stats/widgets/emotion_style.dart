import 'package:flutter/material.dart';

import '../../../data/models/check_in_model.dart';
import '../../core/theme/app_colors.dart';

/// How each emotion looks on the stats screen.
extension EmotionStyle on Emotion {
  String get emoji => switch (this) {
    Emotion.happiness => '😊',
    Emotion.sadness => '😢',
    Emotion.fear => '😨',
    Emotion.anger => '😠',
    Emotion.disgust => '🤢',
    Emotion.surprise => '😲',
  };

  Color get color => switch (this) {
    Emotion.happiness => const Color(0xFF6CC070),
    Emotion.sadness => AppColors.secondary,
    Emotion.fear => AppColors.primary,
    Emotion.anger => AppColors.accent,
    Emotion.disgust => const Color(0xFF9BBF5A),
    Emotion.surprise => const Color(0xFFF2B33D),
  };
}
