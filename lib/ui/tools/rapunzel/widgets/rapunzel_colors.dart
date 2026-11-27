import 'package:flutter/material.dart';

/// The night-sky palette of the Rapunzel's lantern screen: deep indigo sky,
/// cream stars and warm amber lanterns.
abstract final class RapunzelColors {
  static const skyTop = Color(0xFF070B1E);
  static const skyHorizon = Color(0xFF252C57);
  static const star = Color(0xFFFFF6DE);
  static const moon = Color(0xFFFFF3D0);
  static const creamText = Color(0xFFFFF3D0);
  static const creamMuted = Color(0xB3FFF3D0);

  /// Paper of a lit lantern, top to bottom.
  static const lanternTop = Color(0xFFFFE3A1);
  static const lanternBottom = Color(0xFFF8840E);

  /// Paper of an unlit lantern.
  static const lanternDarkTop = Color(0xFF7A6A58);
  static const lanternDarkBottom = Color(0xFF55483B);

  static const cap = Color(0xFF4A2E12);
  static const flameOuter = Color(0xFFFF9F1C);
  static const flameCore = Color(0xFFFFF3C4);
  static const glow = Color(0xFFFFC966);
}
