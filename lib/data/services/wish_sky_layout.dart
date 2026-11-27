import 'dart:isolate';
import 'dart:math';
import 'dart:ui' show Offset;

/// One star of the night sky, in normalized coordinates (0..1 on both axes),
/// so the layout does not depend on the screen size.
class SkyStar {
  const SkyStar(this.position, this.radius, this.alpha);

  final Offset position;
  final double radius;
  final double alpha;
}

/// The layout of the sky: where the stars are and where each background
/// lantern floats, all in normalized coordinates.
class SkyLayout {
  const SkyLayout({required this.stars, required this.lanternSlots});

  final List<SkyStar> stars;

  /// One slot per background lantern, spread over the upper part of the sky.
  final List<Offset> lanternSlots;
}

/// Builds the sky layout of the Rapunzel's lantern screen.
///
/// Placing the stars and the lanterns is pure CPU work over a seeded random
/// sequence; with many wishes on screen it is exactly the kind of work that
/// would jank the first frame if it ran on the UI isolate, so it runs on a
/// background isolate — the `math` calls and `Offset`s are plain Dart values
/// that cross the isolate boundary by copy. The seed keeps each user's sky
/// stable between visits.
class WishSkyLayout {
  const WishSkyLayout({this.starCount = 90});

  static const _defaultStarCount = 90;

  /// How many stars the sky is scattered with.
  final int starCount;

  Future<SkyLayout> generate({
    required int lanternCount,
    required int seed,
  }) {
    // Locals rather than fields: the closure must not capture `this`.
    final starCount = this.starCount;
    return Isolate.run(
      () => buildSkyLayout(
        lanternCount: lanternCount,
        seed: seed,
        starCount: starCount,
      ),
      debugName: 'rapunzel-sky-layout',
    );
  }
}

/// The CPU-heavy part, on its own so it can be tested without an isolate.
/// Deterministic for the same [seed], which is what keeps the sky still
/// between rebuilds.
SkyLayout buildSkyLayout({
  required int lanternCount,
  required int seed,
  int starCount = WishSkyLayout._defaultStarCount,
}) {
  final random = Random(seed);
  final stars = [
    for (var i = 0; i < starCount; i++)
      SkyStar(
        Offset(random.nextDouble(), random.nextDouble() * 0.9),
        0.6 + random.nextDouble() * 1.3,
        0.25 + random.nextDouble() * 0.75,
      ),
  ];

  // Lanterns on a golden-angle spiral from the middle of the sky, with a
  // jitter, so they spread evenly without overlapping and still look hand
  // placed. Clamped to the upper 70% of the sky, away from the big lantern
  // held at the bottom.
  const goldenAngle = 2.39996322972865332; // radians
  final slots = <Offset>[];
  for (var i = 0; i < lanternCount; i++) {
    final radius = 0.34 * sqrt(i + 1) / sqrt(max(lanternCount, 1));
    final angle = i * goldenAngle + random.nextDouble() * 0.6;
    final x = (0.5 + radius * cos(angle) + (random.nextDouble() - 0.5) * 0.06)
        .clamp(0.08, 0.92);
    final y = (0.4 - radius * 0.8 * sin(angle) + (random.nextDouble() - 0.5) * 0.05)
        .clamp(0.06, 0.7);
    slots.add(Offset(x, y));
  }
  return SkyLayout(stars: stars, lanternSlots: slots);
}
