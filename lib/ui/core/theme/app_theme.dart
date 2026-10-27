import 'package:flutter/material.dart';

import 'app_colors.dart';

/// The app theme built from the palette in the design wiki (MS6 §2.3).
///
/// Material needs a value for every role in its scheme. Given only a seed it
/// generates the missing ones, and the ones it generates for light surfaces
/// and for text on colour come out white, which the palette does not have.
/// So every role is named here instead of seeded.
abstract final class AppTheme {
  static ThemeData get light => ThemeData(
    colorScheme: _scheme,
    scaffoldBackgroundColor: AppColors.background,
    // Tick marks and the value bubble also come from the scheme, and are
    // easy to miss because they only show while the slider is being dragged.
    sliderTheme: SliderThemeData(
      activeTickMarkColor: AppColors.text.withValues(alpha: 0.25),
      inactiveTickMarkColor: AppColors.text.withValues(alpha: 0.15),
      valueIndicatorColor: AppColors.text,
      valueIndicatorTextStyle: const TextStyle(color: AppColors.background),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: AppColors.primary,
      selectionColor: AppColors.primary.withValues(alpha: 0.3),
      selectionHandleColor: AppColors.primary,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.panel,
      surfaceTintColor: Colors.transparent,
    ),
  );

  /// Light tones go to the warm surfaces of the palette, and anything that
  /// sits on a saturated colour gets the cream [AppColors.background], which
  /// is what the wiki uses for light-on-dark.
  static final _scheme = ColorScheme(
    brightness: Brightness.light,

    primary: AppColors.primary,
    onPrimary: AppColors.text,
    primaryContainer: AppColors.surfaceDim,
    onPrimaryContainer: AppColors.text,

    secondary: AppColors.secondary,
    onSecondary: AppColors.background,
    secondaryContainer: AppColors.panel,
    onSecondaryContainer: AppColors.text,

    tertiary: AppColors.accent,
    onTertiary: AppColors.background,
    tertiaryContainer: AppColors.panel,
    onTertiaryContainer: AppColors.text,

    error: AppColors.error,
    onError: AppColors.background,
    errorContainer: AppColors.panel,
    onErrorContainer: AppColors.error,

    surface: AppColors.background,
    onSurface: AppColors.text,
    onSurfaceVariant: AppColors.textMuted,
    surfaceContainerLowest: AppColors.panel,
    surfaceContainerLow: AppColors.panel,
    surfaceContainer: AppColors.background,
    surfaceContainerHigh: AppColors.surfaceDim,
    surfaceContainerHighest: AppColors.surfaceDim,
    surfaceDim: AppColors.surfaceDim,
    surfaceBright: AppColors.panel,

    outline: AppColors.surfaceDim,
    outlineVariant: AppColors.surfaceDim,
    shadow: AppColors.text,
    scrim: AppColors.text,

    // Snack bars and tooltips use these, so they stay dark brown on cream.
    inverseSurface: AppColors.text,
    onInverseSurface: AppColors.background,
    inversePrimary: AppColors.primary,

    // No tint, or elevated surfaces drift away from the palette.
    surfaceTint: Colors.transparent,
  );
}
