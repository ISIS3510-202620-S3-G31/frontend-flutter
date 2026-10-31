import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/pending_write_model.dart';
import '../services/auth_service.dart';
import '../services/connectivity_service.dart';
import '../services/local/pending_write_storage.dart';
import '../services/remote/pending_write_firestore_service.dart';


class OfflineSyncRepository {
  OfflineSyncRepository({
    PendingWriteStorage? storage,
    PendingWriteFirestoreService? remote,
    ConnectivityService? connectivity,
    AuthService? auth,
  }) : _storage = storage ?? PendingWriteStorage(),
       _remote = remote ?? PendingWriteFirestoreService(),
       _connectivity = connectivity ?? ConnectivityService(),
       _auth = auth ?? AuthService();

  /// One queue for the whole app, so it is watched by a single listener.
  static final shared = OfflineSyncRepository();

  /// Long enough for a slow connection, short enough not to leave a spinner
  /// on screen when the "connection" has no internet behind it.
  static const _timeout = Duration(seconds: 8);

  final PendingWriteStorage _storage;
  final PendingWriteFirestoreService _remote;
  final ConnectivityService _connectivity;
  final AuthService _auth;

  StreamSubscription<bool>? _onlineChanges;
  bool _flushing = false;

  Future<SaveOutcome> save(PendingWrite write) async {
    final sent = _remote.set(write.path, write.data)..ignore();
    if (await _isOnline()) {
      try {
        await sent.timeout(_timeout);
        return SaveOutcome.saved;
      } on Exception catch (error) {
        debugPrint('[OfflineSync] Queued ${write.path}: $error');
      }
    }
    await _storage.add(write);
    return SaveOutcome.savedOffline;
  }


  void start() {
    if (_onlineChanges != null) return;
    _onlineChanges = _connectivity.onlineChanges
        .where((online) => online)
        .listen((_) => unawaited(flush()));
    unawaited(flush());
  }


  Future<void> flush() async {
    final userId = _auth.currentUserId;
    if (_flushing || userId == null || !await _isOnline()) return;
    _flushing = true;
    try {
      for (final write in await _storage.pendingFor(userId)) {
        await _remote.set(write.path, write.data).timeout(_timeout);
        await _storage.remove(write.path);
      }
    } on Exception catch (error) {
      debugPrint('[OfflineSync] Will retry later: $error');
    } finally {
      _flushing = false;
    }
  }

  Future<bool> _isOnline() async {
    try {
      return await _connectivity.isOnline();
    } on Exception {
      return true;
    }
  }
}
