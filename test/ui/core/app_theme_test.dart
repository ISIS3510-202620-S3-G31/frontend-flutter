import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/ui/core/theme/app_colors.dart';
import 'package:frontend_flutter/ui/core/theme/app_theme.dart';

void main() {
  /// The palette of the design wiki (MS6 §2.3), plus the warm surface derived
  /// from the background for cards.
  final palette = <int>{
    for (final color in [
      AppColors.primary,
      AppColors.secondary,
      AppColors.accent,
      AppColors.background,
      AppColors.text,
      AppColors.success,
      AppColors.warning,
      AppColors.error,
      AppColors.surfaceDim,
    ])
      color.toARGB32() & 0xFFFFFF,
  };

  test('the palette itself has no white', () {
    expect(palette, isNot(contains(0xFFFFFF)));
  });

  test('every role of the scheme comes from the palette', () {
    final scheme = AppTheme.light.colorScheme;
    final roles = <String, Color>{
      'primary': scheme.primary,
      'onPrimary': scheme.onPrimary,
      'primaryContainer': scheme.primaryContainer,
      'onPrimaryContainer': scheme.onPrimaryContainer,
      'secondary': scheme.secondary,
      'onSecondary': scheme.onSecondary,
      'secondaryContainer': scheme.secondaryContainer,
      'onSecondaryContainer': scheme.onSecondaryContainer,
      'tertiary': scheme.tertiary,
      'onTertiary': scheme.onTertiary,
      'tertiaryContainer': scheme.tertiaryContainer,
      'onTertiaryContainer': scheme.onTertiaryContainer,
      'error': scheme.error,
      'onError': scheme.onError,
      'errorContainer': scheme.errorContainer,
      'onErrorContainer': scheme.onErrorContainer,
      'surface': scheme.surface,
      'onSurface': scheme.onSurface,
      'onSurfaceVariant': scheme.onSurfaceVariant,
      'surfaceContainerLowest': scheme.surfaceContainerLowest,
      'surfaceContainerLow': scheme.surfaceContainerLow,
      'surfaceContainer': scheme.surfaceContainer,
      'surfaceContainerHigh': scheme.surfaceContainerHigh,
      'surfaceContainerHighest': scheme.surfaceContainerHighest,
      'surfaceDim': scheme.surfaceDim,
      'surfaceBright': scheme.surfaceBright,
      'outline': scheme.outline,
      'outlineVariant': scheme.outlineVariant,
      'shadow': scheme.shadow,
      'scrim': scheme.scrim,
      'inverseSurface': scheme.inverseSurface,
      'onInverseSurface': scheme.onInverseSurface,
      'inversePrimary': scheme.inversePrimary,
      'surfaceTint': scheme.surfaceTint,
    };

    for (final role in roles.entries) {
      // A fully transparent role paints nothing, whatever its channels say.
      if (role.value.a == 0) continue;
      expect(
        palette,
        contains(role.value.toARGB32() & 0xFFFFFF),
        reason: '${role.key} is outside the palette',
      );
    }
  });

  test('no screen hardcodes a Material white or black', () {
    final offenders = <String>[];
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      final source = file.readAsStringSync();
      for (final banned in ['Colors.white', 'Colors.black']) {
        if (source.contains(banned)) offenders.add('${file.path}: $banned');
      }
    }
    expect(offenders, isEmpty);
  });
}
