import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/wish_model.dart';
import '../../../../data/services/wish_sky_layout.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/circle_icon_button.dart';
import '../view_model/rapunzel_sky_view_model.dart';
import 'lantern_painter.dart';
import 'night_sky_painter.dart';
import 'rapunzel_colors.dart';
import 'wish_editor_screen.dart';
import 'wish_list_screen.dart';

class RapunzelSkyScreen extends StatefulWidget {
  const RapunzelSkyScreen({super.key, this.viewModel});

  final RapunzelSkyViewModel? viewModel;

  @override
  State<RapunzelSkyScreen> createState() => _RapunzelSkyScreenState();
}

class _RapunzelSkyScreenState extends State<RapunzelSkyScreen> {
  static final _dateFormat = DateFormat('MMM d, yyyy');

  late final RapunzelSkyViewModel _viewModel =
      widget.viewModel ?? RapunzelSkyViewModel();
  late final bool _ownsViewModel = widget.viewModel == null;
  String? _shownReadingId;

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(_onViewModelChanged);
    unawaited(_viewModel.load());
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    if (_ownsViewModel) _viewModel.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    final message = _viewModel.takeMessage();
    if (message != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
    final reading = _viewModel.reading;
    if (reading == null) {
      _shownReadingId = null;
    } else if (mounted && _shownReadingId != reading.id) {
      _shownReadingId = reading.id;
      unawaited(_showWish(reading));
    }
  }

  Future<void> _showWish(Wish wish) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: RapunzelColors.skyHorizon,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _viewModel.isLit(wish) ? 'A wish in the sky' : 'A wish held',
              style: AppText.bodyMuted.copyWith(
                color: RapunzelColors.creamMuted,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              wish.text,
              style: AppText.h3.copyWith(color: RapunzelColors.creamText),
            ),
            const SizedBox(height: 12),
            Text(
              _dateFormat.format(wish.createdAt),
              style: AppText.bodyMuted.copyWith(
                color: RapunzelColors.creamMuted,
              ),
            ),
          ],
        ),
      ),
    );
    _viewModel.closeReading();
  }

  Future<void> _openWishList() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const WishListScreen()),
    );
    if (mounted) unawaited(_viewModel.refresh());
  }

  Future<void> _openEditorForNewWish() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const WishEditorScreen()),
    );
    if (mounted) unawaited(_viewModel.refresh());
  }

  void _finish() => Navigator.maybePop(context, true);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: Scaffold(
            backgroundColor: RapunzelColors.skyTop,
            body: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                    child: Row(
                      children: [
                        CircleIconButton(
                          asset: 'assets/icons/ic_chevron_left.svg',
                          semanticLabel: 'Back',
                          onPressed: () => Navigator.maybePop(context),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Rapunzel's lantern",
                                maxLines: 1,
                                style: AppText.h1.copyWith(
                                  color: RapunzelColors.creamText,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        CircleIconButton(
                          asset: 'assets/icons/ic_tools.svg',
                          semanticLabel: 'Your wishes',
                          onPressed: _openWishList,
                        ),
                        const SizedBox(width: 12),
                        CircleIconButton(
                          asset: 'assets/icons/ic_check.svg',
                          semanticLabel: 'Finish',
                          onPressed: _finish,
                        ),
                      ],
                    ),
                  ),
                  if (!_viewModel.isLoading && _viewModel.wishes.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                      child: Text(
                        'Your sky is empty. Write your first wish.',
                        textAlign: TextAlign.center,
                        style: AppText.body.copyWith(
                          color: RapunzelColors.creamText,
                        ),
                      ),
                    ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final size = Size(
                          constraints.maxWidth,
                          constraints.maxHeight,
                        );
                        return _viewModel.isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: RapunzelColors.creamText,
                                ),
                              )
                            : _SkyStage(
                                viewModel: _viewModel,
                                skySize: size,
                                onWriteWish: _openEditorForNewWish,
                              );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The sky itself: static sky painter plus one animated, RepaintBoundary'd layer per lantern that holds an animation slot.
class _SkyStage extends StatelessWidget {
  const _SkyStage({
    required this.viewModel,
    required this.skySize,
    required this.onWriteWish,
  });

  final RapunzelSkyViewModel viewModel;
  final Size skySize;

  /// Opens the editor to write a new wish; shown while no lantern is held.
  final VoidCallback onWriteWish;

  @override
  Widget build(BuildContext context) {
    final layout = viewModel.layout;
    final staticLanterns = <StaticLantern>[];
    final animated = <Widget>[];
    if (layout != null) {
      for (final (wish, slot) in viewModel.backgroundLanterns) {
        final motion = viewModel.motionOf(wish.id);
        if (motion == null) {
          staticLanterns.add(StaticLantern(slot, lit: viewModel.isLit(wish)));
        } else {
          animated.add(
            _animatedLantern(
              id: wish.id,
              slot: slot,
              box: NightSkyPainter.lanternSize + 10,
              lit: viewModel.isLit(wish),
              motion: motion,
              seed: wish.id.hashCode,
            ),
          );
        }
      }
    }
    final foreground = viewModel.foreground;
    final foregroundMotion = foreground == null
        ? null
        : viewModel.motionOf(foreground.id);
    if (foreground != null && foregroundMotion != null) {
      animated.add(
        _animatedLantern(
          id: foreground.id,
          slot: RapunzelSkyViewModel.foregroundSlot,
          box: 116,
          lit: true,
          motion: foregroundMotion,
          seed: foreground.id.hashCode,
        ),
      );
    }

    return GestureDetector(
      key: const Key('rapunzel-sky-stage'),
      behavior: HitTestBehavior.opaque,
      onTapUp: (details) => viewModel.tapAt(details.localPosition, skySize),
      onVerticalDragEnd: (details) =>
          viewModel.onVerticalDragEnd(details.velocity.pixelsPerSecond.dy),
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                size: skySize,
                painter: NightSkyPainter(
                  layout:
                      layout ?? const SkyLayout(stars: [], lanternSlots: []),
                  staticLanterns: staticLanterns,
                  foreground: foreground != null && foregroundMotion == null
                      ? RapunzelSkyViewModel.foregroundSlot
                      : null,
                ),
              ),
            ),
          ),
          ...animated,
          if (foreground != null && foregroundMotion != LanternMotion.releasing)
            Positioned(
              left: 0,
              right: 0,
              bottom: 20,
              child: Text(
                'Swipe up to release your lantern',
                textAlign: TextAlign.center,
                style: AppText.body.copyWith(color: RapunzelColors.creamMuted),
              ),
            ),
          // No lantern held: offer to write the next wish, like the unlit
          // big lantern of the Kotlin app.
          if (foreground == null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 20,
              child: Center(
                child: FilledButton(
                  onPressed: onWriteWish,
                  style: FilledButton.styleFrom(
                    backgroundColor: RapunzelColors.lanternBottom,
                    foregroundColor: RapunzelColors.skyTop,
                    shape: const StadiumBorder(),
                    textStyle: AppText.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Write a wish'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _animatedLantern({
    required String id,
    required Offset slot,
    required double box,
    required bool lit,
    required LanternMotion motion,
    required int seed,
  }) {
    return _AnimatedLantern(
      // A new motion means a new state, so the controller restarts.
      key: ValueKey('$id-$motion'),
      slot: slot,
      skySize: skySize,
      box: box,
      lit: lit,
      motion: motion,
      seed: seed,
      onCompleted: switch (motion) {
        LanternMotion.lighting => () => viewModel.completeLighting(id),
        LanternMotion.releasing => () => unawaited(viewModel.completeRelease()),
        LanternMotion.bobbing => null,
      },
    );
  }
}

/// One lantern with its own AnimationController, repainting only inside its
/// own RepaintBoundary. Bobbing loops; lighting and releasing run once and
/// call [onCompleted].
class _AnimatedLantern extends StatefulWidget {
  const _AnimatedLantern({
    super.key,
    required this.slot,
    required this.skySize,
    required this.box,
    required this.lit,
    required this.motion,
    required this.seed,
    this.onCompleted,
  });

  /// Normalized position in the sky.
  final Offset slot;
  final Size skySize;

  /// Side of the lantern's box, in logical pixels.
  final double box;
  final bool lit;
  final LanternMotion motion;
  final int seed;
  final VoidCallback? onCompleted;

  @override
  State<_AnimatedLantern> createState() => _AnimatedLanternState();
}

class _AnimatedLanternState extends State<_AnimatedLantern>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    final duration = switch (widget.motion) {
      LanternMotion.bobbing => Duration(
        milliseconds: 2400 + widget.seed % 5 * 300,
      ),
      LanternMotion.lighting => const Duration(milliseconds: 700),
      LanternMotion.releasing => const Duration(milliseconds: 2400),
    };
    _controller = AnimationController(vsync: this, duration: duration);
    if (widget.motion == LanternMotion.bobbing) {
      _controller.repeat(reverse: true);
    } else {
      _controller.addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onCompleted?.call();
      });
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final box = widget.box;
        double left;
        double top;
        double side = box;
        var light = widget.lit ? 1.0 : 0.0;
        var flamePhase = 0.0;
        switch (widget.motion) {
          case LanternMotion.bobbing:
            left =
                widget.slot.dx * widget.skySize.width +
                math.cos(math.pi * t) * 2;
            top =
                widget.slot.dy * widget.skySize.height +
                math.sin(2 * math.pi * t) * 4;
            flamePhase = 2 * math.pi * t * 3;
          case LanternMotion.lighting:
            left = widget.slot.dx * widget.skySize.width;
            top = widget.slot.dy * widget.skySize.height;
            light = Curves.easeOut.transform(t);
            flamePhase = 2 * math.pi * t * 6;
          case LanternMotion.releasing:
            final p = Curves.easeOutCubic.transform(t);
            final startY = widget.slot.dy * widget.skySize.height;
            final y = startY + (-0.35 * widget.skySize.height - startY) * p;
            final x =
                widget.slot.dx * widget.skySize.width +
                math.sin(p * math.pi) * 24 * (widget.seed.isEven ? 1 : -1);
            left = x;
            top = y;
            side = box * (1 + 0.7 * p);
            light = 1;
            flamePhase = 2 * math.pi * p * 8;
        }
        return Positioned(
          left: left - side / 2,
          top: top - side / 2,
          width: side,
          height: side,
          child: RepaintBoundary(
            child: CustomPaint(
              size: Size(side, side),
              painter: LanternPainter(
                lit: widget.lit || light > 0.5,
                light: light,
                flamePhase: flamePhase,
              ),
            ),
          ),
        );
      },
    );
  }
}
