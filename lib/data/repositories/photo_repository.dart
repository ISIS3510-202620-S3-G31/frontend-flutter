import 'package:camera/camera.dart' show XFile;
import 'package:flutter/foundation.dart';

import '../models/photo_model.dart';
import '../services/auth_service.dart';
import '../services/connectivity_service.dart';
import '../services/local/photo_cache.dart';
import '../services/local/photo_dao.dart';
import '../services/local/photo_storage_service.dart';
import '../services/remote/photo_remote_service.dart';

class PhotoRepository {
  PhotoRepository({
    PhotoStorageService? storage,
    PhotoDao? dao,
    PhotoCache? cache,
    PhotoRemoteService? remote,
    ConnectivityService? connectivity,
    AuthService? auth,
  }) : _storage = storage ?? PhotoStorageService(),
       _dao = dao ?? PhotoDao(),
       _cache = cache ?? PhotoCache(),
       _remote = remote ?? PhotoRemoteService(),
       _connectivity = connectivity ?? ConnectivityService(),
       _auth = auth ?? AuthService();

  final PhotoStorageService _storage;
  final PhotoDao _dao;
  final PhotoCache _cache;
  final PhotoRemoteService _remote;
  final ConnectivityService _connectivity;
  final AuthService _auth;

  bool _uploading = false;
  bool _leftoversChecked = false;

  Future<DailyPhoto?> photoOf(DateTime day) async {
    final userId = _auth.currentUserId;
    if (userId == null) return null;
    final file = await _storage.photoFor(userId, day);
    return file == null ? null : DailyPhoto(day: day, file: file);
  }

  /// The days of [days] with a photo already on this phone. Disk only, so it
  /// is fast enough to run before the camera starts.
  Future<Set<DateTime>> daysOnThisPhone(List<DateTime> days) async {
    final userId = _auth.currentUserId;
    if (userId == null) return <DateTime>{};
    final saved = await _dao.daysBetween(userId, days.first, days.last);
    // Photos taken before the local table existed have a file but no row.
    for (final day in days) {
      if (!saved.contains(day) &&
          await _storage.photoFor(userId, day) != null) {
        await _dao.insert(userId, day);
        saved.add(day);
      }
    }
    return saved;
  }

  /// The days of [days] this account has a photo for in Firebase, whichever
  /// phone took it.
  ///
  /// Needs the network, so it is kept apart from [daysOnThisPhone]: the week
  /// shows what this phone holds right away and fills in the rest when the
  /// answer arrives. Empty when it cannot be asked.
  Future<Set<DateTime>> daysInFirebase(List<DateTime> days) async {
    final userId = _auth.currentUserId;
    if (userId == null) return <DateTime>{};
    try {
      return await _remote.daysWithPhoto(userId, days.first, days.last);
    } on Exception catch (error) {
      debugPrint('[PhotoOfTheDay] Could not read the other days: $error');
      return <DateTime>{};
    }
  }

  /// Every day of [days] with a photo, here or in Firebase.
  Future<Set<DateTime>> daysWithPhoto(List<DateTime> days) async => {
    ...await daysOnThisPhone(days),
    ...await daysInFirebase(days),
  };

  /// The photo of [day] wherever it is: taken on this phone, already cached
  /// from another one, or downloaded now and cached for next time.
  ///
  /// Null when the account has no photo that day, or when it is only in
  /// Firebase and there is no connection to fetch it.
  Future<DailyPhoto?> anyPhotoOf(DateTime day) async {
    final userId = _auth.currentUserId;
    if (userId == null) return null;

    final own = await _storage.photoFor(userId, day);
    if (own != null) return DailyPhoto(day: day, file: own);

    final cached = await _cache.photoFor(userId, day);
    if (cached != null) return DailyPhoto(day: day, file: cached);

    // Firebase Storage keeps retrying a download for minutes without a
    // connection; better to say no at once.
    if (!await _connectivity.isOnline()) return null;
    try {
      final bytes = await _remote.download(userId, day);
      if (bytes == null) return null;
      return DailyPhoto(day: day, file: await _cache.save(userId, day, bytes));
    } on Exception catch (error) {
      debugPrint('[PhotoOfTheDay] Could not download that day: $error');
      return null;
    }
  }

  /// Drops what this phone cached for [userId], on sign-out.
  Future<void> forgetCached(String userId) => _cache.forget(userId);

  /// Saves on the phone first, so taking a photo never needs internet.
  Future<DailyPhoto> savePhoto(DateTime day, XFile photo) async {
    final userId = _auth.currentUserId;
    if (userId == null) {
      throw StateError('Only a signed-in user can save a photo.');
    }
    final file = await _storage.save(userId, day, photo);
    await _dao.insert(userId, day);
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
      for (final day in await _dao.notSyncedDays(userId)) {
        final file = await _storage.photoFor(userId, day);
        if (file == null) continue;
        await _remote.upload(userId, day, file);
        await _dao.markSynced(userId, day);
      }
    } finally {
      _uploading = false;
    }
    return true;
  }

  /// Clears what the app left behind when photos were shared by every account
  /// on the phone. Runs once per session and does nothing after the first
  /// time, since there is nothing left to delete.
  Future<void> discardSharedLeftovers() async {
    if (_leftoversChecked) return;
    _leftoversChecked = true;
    try {
      await _storage.deleteSharedLeftovers();
      await _dao.deleteSharedDatabase();
    } on Exception catch (error) {
      // Old files taking up space is not worth failing the screen over.
      debugPrint('[PhotoOfTheDay] Could not clear the old photos: $error');
    }
  }

  Stream<bool> get onlineChanges => _connectivity.onlineChanges;
}
