import 'package:flutter/material.dart';

import 'lantern_painter.dart';

/// One paper lantern drawn once, with a steady flame when lit: the small icon of the editor and the rows of the wish list.
class LanternIcon extends StatelessWidget {
  const LanternIcon({
    super.key,
    required this.lit,
    required this.width,
    required this.height,
  });

  final bool lit;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(painter: LanternPainter(lit: lit)),
    );
  }
}
