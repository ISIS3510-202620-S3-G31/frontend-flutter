import 'package:camera/camera.dart' show XFile;

import '../models/photo_model.dart';
import '../services/auth_service.dart';
import '../services/connectivity_service.dart';
import '../services/local/photo_dao.dart';
import '../services/local/photo_storage_service.dart';
import '../services/remote/photo_remote_service.dart';

class PhotoRepository {
  PhotoRepository({
    PhotoStorageService? storage,
    PhotoDao? dao,
    PhotoRemoteService? remote,
    ConnectivityService? connectivity,
    AuthService? auth,
  }) : _storage = storage ?? PhotoStorageService(),
       _dao = dao ?? PhotoDao(),
       _remote = remote ?? PhotoRemoteService(),
       _connectivity = connectivity ?? ConnectivityService(),
       _auth = auth ?? AuthService();

  final PhotoStorageService _storage;
  final PhotoDao _dao;
  final PhotoRemoteService _remote;
  final ConnectivityService _connectivity;
  final AuthService _auth;

  bool _uploading = false;

  Future<DailyPhoto?> photoOf(DateTime day) async {
    final file = await _storage.photoFor(day);
    return file == null ? null : DailyPhoto(day: day, file: file);
  }

  Future<Set<DateTime>> daysWithPhoto(List<DateTime> days) async {
    final saved = await _dao.daysBetween(days.first, days.last);
    // Photos taken before the local table existed have a file but no row.
    for (final day in days) {
      if (!saved.contains(day) && await _storage.photoFor(day) != null) {
        await _dao.insert(day);
        saved.add(day);
      }
    }
    return saved;
  }

  /// Saves on the phone first, so taking a photo never needs internet.
  Future<DailyPhoto> savePhoto(DateTime day, XFile photo) async {
    final file = await _storage.save(day, photo);
    await _dao.insert(day);
    return DailyPhoto(day: day, file: file);
  }

  /// Uploads the photos that are only on the phone. Returns false when there
  /// is no internet, so they stay pending for later.
  ///
  /// A photo is marked as uploaded only after Firebase confirms it; if an
  /// upload fails, that photo and the ones after it stay pending.
  Future<bool> uploadPending() async {
    if (!await _connectivity.isOnline()) return false;
    final userId = _auth.currentUserId;
    // The backend only accepts photos from a signed-in user.
    if (userId == null || _uploading) return true;
    _uploading = true;
    try {
      for (final day in await _dao.notSyncedDays()) {
        final file = await _storage.photoFor(day);
        if (file == null) continue;
        await _remote.upload(userId, day, file);
        await _dao.markSynced(day);
      }
    } finally {
      _uploading = false;
    }
    return true;
  }

  Stream<bool> get onlineChanges => _connectivity.onlineChanges;
}
