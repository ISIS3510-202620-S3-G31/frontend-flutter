import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Text styles from the design system. All weights are 400.
///
/// H1 should be "Sorean"; Figma uses Sora as a stand-in until the font files
/// are available.
abstract final class AppText {
  static TextStyle get h1 =>
      GoogleFonts.sora(fontSize: 28, height: 1.2, color: AppColors.text);
  static TextStyle get h2 =>
      GoogleFonts.figtree(fontSize: 22, height: 1.3, color: AppColors.text);
  static TextStyle get h3 =>
      GoogleFonts.figtree(fontSize: 18, height: 1.3, color: AppColors.text);
  static TextStyle get body =>
      GoogleFonts.figtree(fontSize: 14, height: 1.4, color: AppColors.text);

  /// Body text at 70% opacity, used for subtitles and secondary labels.
  static TextStyle get bodyMuted =>
      body.copyWith(color: AppColors.text.withValues(alpha: 0.7));

  /// "Scream Tank" title only.
  static TextStyle get wordmark =>
      GoogleFonts.sonsieOne(fontSize: 30, height: 1.2, color: AppColors.text);
}
