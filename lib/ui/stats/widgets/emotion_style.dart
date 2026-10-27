import 'package:flutter/material.dart';

import '../../../data/models/check_in_model.dart';
import '../../core/theme/app_colors.dart';

/// How each emotion looks on the stats screen, using only palette colors.
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
    Emotion.happiness => AppColors.success,
    Emotion.sadness => AppColors.secondary,
    Emotion.fear => AppColors.primary,
    Emotion.anger => AppColors.accent,
    Emotion.disgust => AppColors.error,
    Emotion.surprise => AppColors.warning,
  };
}
