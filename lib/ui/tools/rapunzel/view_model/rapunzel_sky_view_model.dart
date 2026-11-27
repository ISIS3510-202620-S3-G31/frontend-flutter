import 'dart:async';
import 'dart:ui' show Offset, Size;

import 'package:flutter/foundation.dart';

import '../../../../data/models/pending_write_model.dart';
import '../../../../data/models/wish_model.dart';
import '../../../../data/repositories/wish_repository.dart';
import '../../../../data/services/wish_sky_layout.dart';

/// What an animated lantern is doing. Only lanterns with a motion have an
/// animation controller and a RepaintBoundary of their own; the rest are
/// drawn once by the sky painter and never repaint.
enum LanternMotion { bobbing, lighting, releasing }

/// What a tap on the sky found.
enum LanternTap { none, read, lighting }

/// The state of the night-sky screen: the wishes floating in the background,
/// the lantern held in the foreground, which lantern reads when tapped and
/// the swipe-up release.
///
/// Performance rules of this screen (wiki §4.5): at most
/// [maxConcurrentAnimations] lanterns animate at the same time, and each
/// animating lantern repaints inside its own RepaintBoundary, so a release
/// never repaints the sky or the other lanterns. The layout of the sky is
/// computed on a background isolate by [WishSkyLayout].
class RapunzelSkyViewModel extends ChangeNotifier {
  RapunzelSkyViewModel({
    WishRepository? repository,
    WishSkyLayout? skyLayout,
    int? maxConcurrentAnimations,
    DateTime Function()? now,
  }) : _repository = repository ?? WishRepository(),
       _skyLayout = skyLayout ?? const WishSkyLayout(),
       _maxConcurrentAnimations =
           maxConcurrentAnimations ?? defaultMaxConcurrentAnimations,
       _now = now ?? DateTime.now;

  static const toolId = 'rapunzel';
  static const toolName = "Rapunzel's lantern";

  /// How many lanterns may animate at once. The rest are drawn static, so
  /// frame time does not grow with the number of wishes.
  static const defaultMaxConcurrentAnimations = 6;

  /// Upward fling speed, in px/s, that releases the held lantern.
  static const releaseVelocityThreshold = -800.0;

  /// Where the held lantern floats, in normalized coordinates.
  static const foregroundSlot = Offset(0.5, 0.76);

  /// Hit radius of a background lantern, in logical pixels.
  static const backgroundHitRadius = 26.0;

  /// Hit radius of the held lantern, in logical pixels.
  static const foregroundHitRadius = 64.0;

  final WishRepository _repository;
  final WishSkyLayout _skyLayout;
  final int _maxConcurrentAnimations;
  final DateTime Function() _now;

  List<Wish> _wishes = const [];
  SkyLayout? _layout;
  Wish? _foreground;
  Wish? _reading;
  bool _loading = true;
  bool _offline = false;
  String? _message;
  final Set<String> _litIds = {};
  final Map<String, LanternMotion> _motions = {};
  StreamSubscription<bool>? _onlineChanges;
  bool _disposed = false;

  List<Wish> get wishes => _wishes;
  SkyLayout? get layout => _layout;
  bool get isLoading => _loading;
  bool get isOffline => _offline;

  /// The lantern held in the foreground: the most recent wish not released
  /// yet, lit. Null when every wish has flown.
  Wish? get foreground => _foreground;

  /// The wish whose text is being read, if any.
  Wish? get reading => _reading;

  int get maxConcurrentAnimations => _maxConcurrentAnimations;

  /// How many lanterns are animating right now, never above the cap.
  int get activeAnimationCount => _motions.length;

  /// The wishes floating in the background, with the slot each one floats at.
  /// Empty until [load] finishes.
  List<(Wish, Offset)> get backgroundLanterns {
    final layout = _layout;
    if (layout == null) return const [];
    final foreground = _foreground;
    final rest = [
      for (final wish in _wishes)
        if (foreground == null || wish.id != foreground.id) wish,
    ];
    return [
      for (var i = 0; i < rest.length && i < layout.lanternSlots.length; i++)
        (rest[i], layout.lanternSlots[i]),
    ];
  }

  /// The motion of the lantern of [wishId], or null when it is drawn static.
  LanternMotion? motionOf(String wishId) => _motions[wishId];

  /// A lantern is lit when its wish was released or when a tap lit it during
  /// this visit.
  bool isLit(Wish wish) => wish.released || _litIds.contains(wish.id);

  /// A snackbar message for the screen, taken once.
  String? takeMessage() {
    final message = _message;
    _message = null;
    return message;
  }

  /// Loads the wishes and builds the sky layout on a background isolate.
  Future<void> load() async {
    _loading = true;
    _notify();
    _offline = !await _repository.isOnline();
    final wishes = await _repository.wishes();
    if (_disposed) return;
    _wishes = wishes;
    _litIds
      ..clear()
      ..addAll(wishes.where((wish) => wish.released).map((wish) => wish.id));
    // The seed is the wishes themselves, so the same wishes always float at
    // the same places, visit after visit.
    final seed = wishes.isEmpty
        ? 0
        : Object.hashAll(wishes.map((wish) => wish.id));
    _layout = await _skyLayout.generate(
      lanternCount: wishes.length,
      seed: seed,
    );
    if (_disposed) return;
    _pickForeground();
    _loading = false;
    _onlineChanges ??= _repository.onlineChanges.listen((online) {
      if (_disposed || online == !_offline) return;
      _offline = !online;
      if (_offline) {
        _message = 'No internet — your wishes stay safe on this phone.';
      }
      _notify();
    });
    _notify();
  }

  /// Reloads after the create-wish screen saved a new wish.
  Future<void> refresh() => load();

  void _pickForeground() {
    _motions.clear();
    // The held lantern always animates, so it gets the first slot.
    final unreleased = _wishes.where((wish) => !wish.released).toList();
    _foreground = unreleased.isEmpty ? null : unreleased.first;
    if (_foreground != null) {
      _motions[_foreground!.id] = LanternMotion.bobbing;
    }
    // Then the background lanterns, until the cap is reached; the rest are
    // drawn static by the sky painter.
    for (final (wish, _) in backgroundLanterns) {
      if (_motions.length >= _maxConcurrentAnimations) break;
      _motions[wish.id] = LanternMotion.bobbing;
    }
  }

  /// A tap at [position] on a sky of [skySize]. Reads the wish of a lit
  /// lantern; lights an unlit one first when a slot is free, or right away
  /// when the cap is already reached.
  LanternTap tapAt(Offset position, Size skySize) {
    if (skySize.isEmpty) return LanternTap.none;
    final normalized = Offset(
      position.dx / skySize.width,
      position.dy / skySize.height,
    );

    final foreground = _foreground;
    if (foreground != null &&
        (normalized - foregroundSlot).distance * skySize.width <
            foregroundHitRadius) {
      _reading = foreground;
      _notify();
      return LanternTap.read;
    }

    (Wish, Offset)? best;
    var bestDistance = double.infinity;
    for (final entry in backgroundLanterns) {
      final distance = (normalized - entry.$2).distance * skySize.width;
      if (distance < backgroundHitRadius && distance < bestDistance) {
        best = entry;
        bestDistance = distance;
      }
    }
    final hit = best?.$1;
    if (hit == null) return LanternTap.none;
    if (isLit(hit)) {
      _reading = hit;
      _notify();
      return LanternTap.read;
    }
    // Unlit: light it. A bobbing slot turns into the lighting animation; a
    // free slot is taken for it; at the cap the flame lights without the
    // animation and the text opens at once, so no wish is lost behind the cap.
    if (_motions.containsKey(hit.id) ||
        _motions.length < _maxConcurrentAnimations) {
      _motions[hit.id] = LanternMotion.lighting;
      _notify();
      return LanternTap.lighting;
    }
    _litIds.add(hit.id);
    _reading = hit;
    _notify();
    return LanternTap.read;
  }

  /// The lighting animation of [wishId] finished: the flame stays lit and the
  /// wish opens.
  void completeLighting(String wishId) {
    _motions.remove(wishId);
    _litIds.add(wishId);
    final wish = _wishById(wishId);
    if (wish != null) _reading = wish;
    _notify();
  }

  /// The end of an upward fling. Returns true when the held lantern starts
  /// its release animation.
  bool onVerticalDragEnd(double velocityY) {
    final foreground = _foreground;
    if (foreground == null ||
        velocityY >= releaseVelocityThreshold ||
        _motions[foreground.id] == LanternMotion.releasing) {
      return false;
    }
    // The release outranks a background bobbing: free one slot if the cap is
    // reached, then take the slot for the release.
    if (!_motions.containsKey(foreground.id) &&
        _motions.length >= _maxConcurrentAnimations) {
      final bobbing = _motions.keys
          .where((id) => _motions[id] == LanternMotion.bobbing)
          .firstOrNull;
      if (bobbing != null) _motions.remove(bobbing);
    }
    _motions[foreground.id] = LanternMotion.releasing;
    _notify();
    return true;
  }

  /// The release animation finished: the wish is marked released locally and
  /// queued for Firestore, and the lantern joins the lit ones in the sky.
  Future<void> completeRelease() async {
    final foreground = _foreground;
    if (foreground == null) return;
    _motions.remove(foreground.id);
    final SaveOutcome outcome;
    try {
      outcome = await _repository.release(foreground);
    } on Exception catch (error) {
      debugPrint('[Rapunzel] Could not save the release: $error');
      if (_disposed) return;
      _message = 'The release could not be saved. Try again.';
      _notify();
      return;
    }
    if (_disposed) return;
    _wishes = [
      for (final wish in _wishes)
        if (wish.id == foreground.id) foreground.copyWith(released: true, releasedAt: _now()) else wish,
    ];
    _litIds.add(foreground.id);
    if (outcome == SaveOutcome.savedOffline) {
      _message = 'Released! It will reach the cloud when you are back online.';
    }
    _pickForeground();
    _notify();
  }

  void closeReading() {
    if (_reading == null) return;
    _reading = null;
    _notify();
  }

  Wish? _wishById(String id) {
    for (final wish in _wishes) {
      if (wish.id == id) return wish;
    }
    return null;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _onlineChanges?.cancel();
    super.dispose();
  }
}
