import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Represents a single recorded emotional tear entry.
class TearEntry {
  const TearEntry({
    required this.id,
    required this.reasonHonored,
    required this.rootEmotion,
    required this.timestamp,
    required this.reliefLevel,
    required this.compassionReflection,
    this.color = AppColors.secondary,
  });

  final String id;
  final String reasonHonored;
  final String rootEmotion;
  final DateTime timestamp;
  final int reliefLevel; // e.g. 8 for Lv. 8/10
  final String compassionReflection;
  final Color color;

  /// Sample tears matching the design mockups.
  static final List<TearEntry> samples = [
    TearEntry(
      id: '1',
      reasonHonored: 'Overwhelm & deadline stress',
      rootEmotion: 'Overwhelm & Anxiety',
      timestamp: DateTime(2026, 9, 18, 22, 42),
      reliefLevel: 8,
      compassionReflection:
          'You allowed your nervous system to reset. Drink a glass of water and rest your eyes for a few minutes.',
      color: AppColors.secondary,
    ),
    TearEntry(
      id: '2',
      reasonHonored: 'Missing someone deeply',
      rootEmotion: 'Grief & Longing',
      timestamp: DateTime(2026, 9, 16, 19, 15),
      reliefLevel: 6,
      compassionReflection:
          'Grief is proof of love that was deeply felt. Be gentle with your tender heart today.',
      color: AppColors.primary,
    ),
    TearEntry(
      id: '3',
      reasonHonored: 'Relief after a hard conversation',
      rootEmotion: 'Vulnerability & Courage',
      timestamp: DateTime(2026, 9, 12, 23, 3),
      reliefLevel: 9,
      compassionReflection:
          'You showed honesty and strength. Notice the lightness in your chest as you let go.',
      color: AppColors.secondary,
    ),
  ];
}
