import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/pending_write_model.dart';
import '../models/wish_model.dart';
import '../services/auth_service.dart';
import '../services/connectivity_service.dart';
import '../services/local/wish_dao.dart';
import '../services/remote/analytics_firestore_service.dart';
import '../services/remote/pending_write_firestore_service.dart';
import 'offline_sync_repository.dart';

/// The wishes of the Rapunzel's lantern tool: sqflite on the phone as the
/// source of truth, Firestore as the backup.
///
/// Every write goes to Firestore right away when there is a connection
/// (Firestore itself keeps it if the write fails) and is queued as a pending
/// write when there is not, so [OfflineSyncRepository] can send it when the
/// connection returns. The analytics events of BQ26 (`wish_created`,
/// `wish_released`, ...) are written here, next to the change they describe.
class WishRepository {
  WishRepository({
    WishDao? dao,
    AuthService? auth,
    AnalyticsFirestoreService? analytics,
    PendingWriteFirestoreService? remote,
    OfflineSyncRepository? sync,
    ConnectivityService? connectivity,
  }) : _dao = dao ?? WishDao(),
       _auth = auth ?? AuthService(),
       _analytics = analytics ?? AnalyticsFirestoreService(),
       _remote = remote ?? PendingWriteFirestoreService(),
       _sync = sync ?? OfflineSyncRepository.shared,
       _connectivity = connectivity ?? ConnectivityService();

  final WishDao _dao;
  final AuthService _auth;
  final AnalyticsFirestoreService _analytics;
  final PendingWriteFirestoreService _remote;
  final OfflineSyncRepository _sync;
  final ConnectivityService _connectivity;

  /// The Firestore document of [wish], the same one the pending-writes queue
  /// writes to. Built as text, so it needs no Firestore (offline queue, tests).
  String pathFor(String userId, Wish wish) => 'users/$userId/wishes/${wish.id}';

  Stream<bool> get onlineChanges => _connectivity.onlineChanges;

  Future<bool> isOnline() async {
    try {
      return await _connectivity.isOnline();
    } catch (_) {
      // When the phone cannot tell, behave as online, as before.
      return true;
    }
  }

  /// All the wishes of the signed-in account, newest first. Empty when nobody
  /// is signed in or the database cannot be read.
  Future<List<Wish>> wishes() async {
    final userId = _auth.currentUserId;
    if (userId == null) return [];
    try {
      return await _dao.all(userId);
    } on Exception catch (error) {
      debugPrint('[Wishes] Could not read the local wishes: $error');
      return [];
    }
  }

  /// Saves a new, still held wish and returns it. Works offline: the wish is
  /// in sqflite at once and the Firestore copy waits in the pending queue.
  Future<Wish> save(String text) async {
    final userId = _requireUser();
    final wish = Wish.create(text);
    await _dao.upsert(userId, wish);
    unawaited(
      _analytics.create(userId, {
        'name': 'wish_created',
        'userId': userId,
        'wish_id': wish.id,
        'text_length': wish.text.length,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
      }),
    );
    await _push(userId, wish);
    return wish;
  }

  /// Releases a wish: its lantern floats up into the sky. The wish stays
  /// saved, now marked released, both on the phone and in the cloud.
  Future<SaveOutcome> release(Wish wish) async {
    final userId = _requireUser();
    final released = wish.copyWith(released: true, releasedAt: DateTime.now());
    await _dao.upsert(userId, released);
    unawaited(
      _analytics.create(userId, {
        'name': 'wish_released',
        'userId': userId,
        'wish_id': released.id,
        'held_seconds': DateTime.now()
            .difference(released.createdAt)
            .inSeconds,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
      }),
    );
    return _push(userId, released);
  }

  /// Firestore right away — it keeps the write on the phone when there is no
  /// real network — plus the pending-writes queue as the second chance that
  /// [OfflineSyncRepository] flushes when the connection returns.
  Future<SaveOutcome> _push(String userId, Wish wish) async {
    final path = pathFor(userId, wish);
    unawaited(_remote.set(path, wish.toMap()).catchError(_report));
    return _sync.track(
      PendingWrite(
        path: path,
        userId: userId,
        data: wish.toMap(),
        createdAt: DateTime.now(),
      ),
    );
  }

  String _requireUser() {
    final userId = _auth.currentUserId;
    if (userId == null) {
      throw const AuthException('Sign in to save your wishes.');
    }
    return userId;
  }

  static void _report(Object error) =>
      debugPrint('[Wishes] Could not reach Firestore: $error');
}
