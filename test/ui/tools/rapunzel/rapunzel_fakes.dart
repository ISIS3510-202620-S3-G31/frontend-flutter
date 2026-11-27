import 'dart:async';
import 'dart:ui' show Offset, Size;

import 'package:frontend_flutter/data/models/pending_write_model.dart';
import 'package:frontend_flutter/data/models/wish_model.dart';
import 'package:frontend_flutter/data/repositories/wish_repository.dart';
import 'package:frontend_flutter/data/services/wish_sky_layout.dart';
import 'package:frontend_flutter/ui/tools/rapunzel/view_model/rapunzel_sky_view_model.dart';

/// A repository that answers from memory, recording what was released.
class FakeWishRepository extends WishRepository {
  FakeWishRepository({List<Wish> stored = const [], this.online = true})
    : _stored = List.of(stored);

  final List<Wish> _stored;
  bool online;
  final List<String> releasedIds = [];
  final _changes = StreamController<bool>.broadcast();

  @override
  Future<List<Wish>> wishes() async => List.of(_stored);

  @override
  Future<SaveOutcome> release(Wish wish) async {
    releasedIds.add(wish.id);
    final index = _stored.indexWhere((stored) => stored.id == wish.id);
    if (index >= 0) {
      _stored[index] = wish.copyWith(
        released: true,
        releasedAt: DateTime(2026, 11, 27, 23),
      );
    }
    return online ? SaveOutcome.saved : SaveOutcome.savedOffline;
  }

  @override
  Future<bool> isOnline() async => online;

  @override
  Stream<bool> get onlineChanges => _changes.stream;

  void goOffline() {
    online = false;
    _changes.add(false);
  }
}

/// A layout with fixed slots, so a test can aim a tap at a known lantern.
class FakeSkyLayout extends WishSkyLayout {
  const FakeSkyLayout();

  @override
  Future<SkyLayout> generate({required int lanternCount, required int seed}) async =>
      SkyLayout(
        stars: const [],
        lanternSlots: [
          for (var i = 0; i < lanternCount; i++) Offset(0.2 + 0.15 * i, 0.3),
        ],
      );
}

Wish wish(String id, {bool released = false}) => Wish(
  id: id,
  text: 'wish $id',
  createdAt: DateTime(2026, 11, 27, 20),
  released: released,
);

/// Newest first, the way the DAO returns them.
final w1 = wish('w1', released: true);
final w2 = wish('w2');
final w3 = wish('w3');

RapunzelSkyViewModel viewModel(
  FakeWishRepository repository, {
  int? maxConcurrentAnimations,
}) => RapunzelSkyViewModel(
  repository: repository,
  skyLayout: const FakeSkyLayout(),
  maxConcurrentAnimations: maxConcurrentAnimations,
  now: () => DateTime(2026, 11, 27, 23),
);

const skySize = Size(400, 800);

/// Pixel position of background lantern [index] in the fake layout.
Offset slotPixel(int index) =>
    Offset((0.2 + 0.15 * index) * skySize.width, 0.3 * skySize.height);
