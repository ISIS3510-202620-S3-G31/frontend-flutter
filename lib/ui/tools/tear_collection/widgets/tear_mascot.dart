import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Sprout mascot character illustration loaded from SVG asset.
class SproutMascot extends StatelessWidget {
  const SproutMascot({
    super.key,
    this.width = 60,
    this.height = 72,
    this.showGroundRipples = false,
  });

  final double width;
  final double height;
  final bool showGroundRipples;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/illustrations/sprout_mascot.svg',
      width: width,
      height: height,
      fit: BoxFit.contain,
    );
  }
}
