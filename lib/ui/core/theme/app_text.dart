import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Text styles from the design system, the same as the Kotlin app's: every
/// title in Sorean, everything else in Figtree. All weights are 400.
abstract final class AppText {
  /// The design's headline font, bundled in assets/fonts.
  static const headlineFamily = 'Sorean';

  static TextStyle get h1 => const TextStyle(
    fontFamily: headlineFamily,
    fontSize: 28,
    height: 1.2,
    color: AppColors.text,
  );
  static TextStyle get h2 =>
      GoogleFonts.figtree(fontSize: 22, height: 1.3, color: AppColors.text);
  static TextStyle get h3 =>
      GoogleFonts.figtree(fontSize: 18, height: 1.3, color: AppColors.text);
  static TextStyle get body =>
      GoogleFonts.figtree(fontSize: 14, height: 1.4, color: AppColors.text);

  /// Body text at 70% opacity, used for subtitles and secondary labels.
  static TextStyle get bodyMuted =>
      body.copyWith(color: AppColors.text.withValues(alpha: 0.7));

  /// "Scream Tank" title.
  static TextStyle get wordmark => h1.copyWith(fontSize: 30);

  /// "Custom breathing" title.
  static TextStyle get breathingTitle => h1;
}
