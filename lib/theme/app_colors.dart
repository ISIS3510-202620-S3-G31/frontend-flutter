import 'package:flutter/material.dart';

/// Color tokens from the Figma variable collection "Colors".
abstract final class AppColors {
  static const primary = Color(0xFFF8840E); // main actions (shutter, mic)
  static const secondary = Color(0xFF2BA79B); // round buttons, soft zone
  static const accent = Color(0xFFEB5249); // live dot, strong meter zone
  static const background = Color(0xFFF9DEAA); // screen bg, text on dark cards
  static const panel = Color(0xFFFDF3E0); // card and panel background
  static const text = Color(0xFF221100); // text, icons, dark cards
  static const success = Color(0xFFC5FAA8); // completed day
  static const warning = Color(0xFFFFF170);
  static const error = Color(0xFFB31212);
}
