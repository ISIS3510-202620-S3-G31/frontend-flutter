import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import 'fortune_stage.dart';

/// Colors of the Fortune Cookie, the Kotlin app's.
abstract final class FortuneColors {
  static const backdropTop = Color(0xFFFCEFD5);
  static const paperTop = Color(0xFFFBEACB);
  static const paperBottom = Color(0xFFFAE3B8);
  static Color get mutedText => AppColors.text.withValues(alpha: 0.62);
}

/// The Fortune Cookie's headline font.
TextStyle fortuneHeadline(double size) => TextStyle(
  fontFamily: AppText.headlineFamily,
  fontSize: size,
  height: 1.25,
  color: AppColors.text,
);

/// The slip of paper with the phrase. The cookie halves rest on its ends.
class FortunePaper extends StatelessWidget {
  const FortunePaper({super.key, required this.quote});

  final String quote;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: fortunePaperSidePadding),
      child: Container(
        constraints: const BoxConstraints(minHeight: 112),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [FortuneColors.paperTop, FortuneColors.paperBottom],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.text.withValues(alpha: 0.18),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          quote,
          textAlign: TextAlign.center,
          style: fortuneHeadline(20),
        ),
      ),
    );
  }
}

/// A rounded button of the Fortune Cookie: light with an icon, or solid
/// orange for the main action.
class FortunePill extends StatelessWidget {
  const FortunePill({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.iconColor,
    this.solid = false,
    this.width = 128,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? iconColor;
  final bool solid;
  final double width;

  @override
  Widget build(BuildContext context) {
    final background = solid
        ? AppColors.primary
        : FortuneColors.backdropTop.withValues(alpha: 0.85);
    return SizedBox(
      width: width,
      height: 44,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(22),
        elevation: solid ? 3 : 1,
        shadowColor: AppColors.primary.withValues(alpha: 0.4),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: iconColor),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
