import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../view_model/fortune_cookie_view_model.dart';
import 'fortune_paper.dart';

const _whole = AssetImage('assets/illustrations/fortune_cookie_whole.webp');
const _left = AssetImage('assets/illustrations/fortune_cookie_left.webp');
const _right = AssetImage('assets/illustrations/fortune_cookie_right.webp');

/// The light under each cookie, one color of the palette for each.
const _lights = [AppColors.primary, AppColors.secondary, AppColors.accent];

/// Space on each side of the paper; the cookie halves rest on its ends.
const fortunePaperSidePadding = 64.0;

/// The largest a cookie is drawn: 1.4 times its size, in the middle.
const _largestScale = 1.4;

/// The three cookies, one on top and two below, floating over colored
/// lights. The chosen one goes to the middle, shakes and splits in two halves
/// that open to the sides, and the paper comes out between them.
///
/// The cookies are images, so the animation only moves, scales, turns and
/// fades them; only the paper and the crumbs, a few small shapes, are drawn
/// frame by frame while they move.
class FortuneStage extends StatefulWidget {
  const FortuneStage({
    super.key,
    required this.phase,
    required this.chosenIndex,
    required this.hasChances,
    required this.previewing,
    required this.onCrack,
    required this.quote,
  });

  final FortunePhase phase;
  final int chosenIndex;
  final bool hasChances;

  /// A recent phrase is being read: the paper shows between open halves
  /// without any cookie being opened.
  final bool previewing;
  final ValueChanged<int> onCrack;

  /// The phrase written on the paper, or null while there is none.
  final String? quote;

  @override
  State<FortuneStage> createState() => _FortuneStageState();
}

class _FortuneStageState extends State<FortuneStage>
    with TickerProviderStateMixin {
  /// The cookies bob gently while the user chooses.
  late final _idle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  /// The whole opening, 2.65 s: to the middle, shake, split, halves aside,
  /// paper out.
  late final _opening = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2650),
  );

  late final _preview = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  late final _travel = _part(0, 420, Curves.fastOutSlowIn);
  late final _shake = _part(420, 920, Curves.linear);
  late final _split = _part(920, 1300, Curves.fastOutSlowIn);
  late final _aside = _part(1300, 1750, Curves.fastOutSlowIn);
  late final _ribbon = _part(1750, 2650, Curves.fastOutSlowIn);

  final List<Timer> _haptics = [];
  int? _decodeWidth;

  Animation<double> _part(int from, int to, Curve curve) => CurvedAnimation(
    parent: _opening,
    curve: Interval(from / 2650, to / 2650, curve: curve),
  );

  @override
  void initState() {
    super.initState();
    _syncIdle();
    if (widget.phase == FortunePhase.revealed) _opening.value = 1;
    if (widget.previewing) _preview.value = 1;
  }

  @override
  void didUpdateWidget(FortuneStage old) {
    super.didUpdateWidget(old);
    if (old.phase != widget.phase) {
      if (widget.phase == FortunePhase.choosing) {
        _opening.value = 0;
      } else if (widget.phase == FortunePhase.opening) {
        _open();
      } else if (_opening.value == 0) {
        _opening.value = 1;
      }
    }
    if (old.previewing != widget.previewing) {
      widget.previewing ? _preview.forward(from: 0) : _preview.value = 0;
    }
    _syncIdle();
  }

  /// The bobbing only runs while it can be seen.
  void _syncIdle() {
    final idle = widget.phase == FortunePhase.choosing && !widget.previewing;
    if (idle && !_idle.isAnimating) {
      _idle.repeat();
    } else if (!idle) {
      _idle.stop();
    }
  }

  void _open() {
    _opening.forward(from: 0);
    // Three light taps while it shakes, a strong one when it splits.
    for (final ms in [420, 580, 740]) {
      _haptics.add(
        Timer(Duration(milliseconds: ms), HapticFeedback.selectionClick),
      );
    }
    _haptics.add(
      Timer(const Duration(milliseconds: 920), HapticFeedback.heavyImpact),
    );
  }

  /// Decodes the three images once, at the largest size they are drawn,
  /// before any cookie is opened: the first split never waits for them.
  void _precache(double cookieSize) {
    final width =
        (cookieSize * _largestScale * MediaQuery.devicePixelRatioOf(context))
            .round();
    if (width == _decodeWidth) return;
    _decodeWidth = width;
    for (final image in [_whole, _left, _right]) {
      precacheImage(ResizeImage(image, width: width), context);
    }
  }

  ImageProvider _sized(AssetImage image) =>
      ResizeImage(image, width: _decodeWidth);

  @override
  void dispose() {
    for (final timer in _haptics) {
      timer.cancel();
    }
    _idle.dispose();
    _opening.dispose();
    _preview.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final cookieSize = math.min(width, height) * 0.34;
        _precache(cookieSize);

        Offset slot(int index) => switch (index) {
          0 => Offset(0, -0.3 * height),
          1 => Offset(-0.29 * width, 0.06 * height),
          _ => Offset(0.29 * width, 0.06 * height),
        };

        return RepaintBoundary(
          child: AnimatedBuilder(
            animation: Listenable.merge([_idle, _opening, _preview]),
            // The stack takes the whole stage: taps only reach what lies
            // inside its bounds, and the side cookies sit far from the middle.
            builder: (context, _) => SizedBox(
              width: width,
              height: height,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  for (var i = 0; i < 3; i++) _light(i, slot(i), cookieSize),
                  for (var i = 0; i < 3; i++) _cookie(i, slot(i), cookieSize),
                  ?_paper(width),
                  ?_halves(width, cookieSize),
                  ?_crumbs(cookieSize),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  double get _bob => math.sin(_idle.value * 2 * math.pi);

  double get _cookiesAlpha => 1 - _preview.value;

  Widget _light(int index, Offset slot, double cookieSize) {
    final alpha =
        (1 - _travel.value) * _cookiesAlpha * (widget.hasChances ? 1 : 0.4);
    if (alpha == 0) return const SizedBox.shrink();
    final size = cookieSize * 0.88;
    return Transform.translate(
      offset: slot + Offset(0, size * 0.45),
      child: Opacity(
        opacity: alpha,
        child: CustomPaint(
          size: Size(size * 1.2, size * 1.6),
          painter: _LightPainter(_lights[index], 0.85 + 0.15 * _bob),
        ),
      ),
    );
  }

  Widget _cookie(int index, Offset slot, double cookieSize) {
    final chosen =
        index == widget.chosenIndex && widget.phase != FortunePhase.choosing;
    // The chosen cookie is replaced by its halves once it splits.
    if (chosen && _split.value > 0) return const SizedBox.shrink();

    final t = _travel.value;
    late final Offset offset;
    late final double scale;
    var turn = 0.0;
    var alpha = 1.0;
    if (chosen) {
      final shake = _shake.value;
      // A tremble that grows and fades before it splits.
      turn =
          math.sin(shake * math.pi * 9) * 7 * math.sin(shake * math.pi) / 180;
      offset = slot * (1 - t);
      scale = 1 + (_largestScale - 1) * t;
    } else if (widget.phase == FortunePhase.choosing) {
      offset = slot + Offset(0, _bob * 6);
      scale = 1;
      alpha = (widget.hasChances ? 1 : 0.45) * _cookiesAlpha;
    } else {
      // The others shrink and leave.
      offset = Offset(slot.dx * (1 + 0.15 * t), slot.dy + 30 * t);
      scale = 1 - 0.3 * t;
      alpha = 1 - t;
    }

    final canOpen =
        widget.phase == FortunePhase.choosing &&
        widget.hasChances &&
        !widget.previewing;
    return Transform.translate(
      offset: offset,
      child: Transform.rotate(
        angle: turn * math.pi,
        child: Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: alpha.clamp(0, 1),
            child: Semantics(
              button: canOpen,
              label: 'Open cookie ${index + 1}',
              child: GestureDetector(
                onTap: canOpen ? () => widget.onCrack(index) : null,
                child: Image(
                  image: _sized(_whole),
                  width: cookieSize,
                  height: cookieSize,
                  gaplessPlayback: true,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The paper comes out of the cookie narrow and very wavy, stretches to
  /// both sides, then grows to its height and flattens to a gentle wave,
  /// with the phrase showing as it flattens.
  Widget? _paper(double width) {
    final quote = widget.quote;
    final progress = widget.previewing ? _preview.value : _ribbon.value;
    if (quote == null || progress == 0) return null;
    final grow = ((progress - 0.55) / 0.45).clamp(0.0, 1.0);
    final restingWave = 112 * fortunePaperRestingWave;
    return FortunePaper(
      quote: quote,
      wave: width * 0.05 * (1 - progress) + restingWave * progress,
      widthFactor: 0.15 + 0.85 * progress,
      heightFactor: 0.18 + 0.82 * grow,
      textOpacity: Curves.easeIn.transform(grow),
    );
  }

  /// Crumbs flying off while the cookie splits.
  Widget? _crumbs(double cookieSize) {
    final split = _split.value;
    if (widget.previewing || split <= 0 || split >= 1) return null;
    return IgnorePointer(
      child: CustomPaint(
        size: Size.square(cookieSize * _largestScale),
        painter: CookieShardsPainter(split),
      ),
    );
  }

  Widget? _halves(double width, double cookieSize) {
    final opening =
        widget.chosenIndex >= 0 &&
        widget.phase != FortunePhase.choosing &&
        _split.value > 0 &&
        !widget.previewing;
    if (!opening && !widget.previewing) return null;

    final split = widget.previewing ? 1.0 : _split.value;
    final aside = widget.previewing ? 1.0 : _aside.value;
    final alpha = widget.previewing
        ? (_preview.value * 3).clamp(0.0, 1.0)
        : 1.0;
    // How far each half moves so its middle ends just past the paper's end.
    final paperEdge = (width - fortunePaperSidePadding * 2) / 2 + 18;
    final spread = math.max(
      0.0,
      paperEdge / 1.3 - cookieSize * 0.2 - cookieSize * 0.32,
    );

    Widget half(AssetImage image, double side) {
      final matrix = Matrix4.identity()
        ..setEntry(3, 2, 0.0012)
        ..translateByDouble(
          side * (cookieSize * 0.32 * split + spread * aside),
          -cookieSize * 0.03 * split,
          0,
          1,
        )
        ..rotateZ(side * 20 * split * math.pi / 180)
        ..rotateY(-side * 16 * split * math.pi / 180);
      return Transform(
        alignment: Alignment(side < 0 ? -0.4 : 0.5, 0.84),
        transform: matrix,
        child: Image(
          image: _sized(image),
          width: cookieSize,
          height: cookieSize,
          gaplessPlayback: true,
        ),
      );
    }

    return Opacity(
      opacity: alpha,
      child: Transform.scale(
        scale: _largestScale - 0.1 * aside,
        child: SizedBox.square(
          dimension: cookieSize,
          child: Stack(children: [half(_left, -1), half(_right, 1)]),
        ),
      ),
    );
  }
}

/// A soft cylinder of colored light standing on a bright disc.
class _LightPainter extends CustomPainter {
  _LightPainter(this.color, this.strength);

  final Color color;
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    final floor = Rect.fromLTWH(
      0,
      size.height * 0.86,
      size.width,
      size.height * 0.14,
    );
    final beam = Rect.fromLTRB(
      size.width * 0.08,
      0,
      size.width * 0.92,
      floor.center.dy,
    );
    canvas.drawRect(
      beam,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0),
            color.withValues(alpha: 0.55 * strength),
          ],
        ).createShader(beam),
    );
    canvas.drawOval(
      floor.deflate(size.width * 0.08),
      Paint()..color = color.withValues(alpha: 0.9 * strength),
    );
  }

  @override
  bool shouldRepaint(_LightPainter old) =>
      old.color != color || old.strength != strength;
}
