import 'package:camera/camera.dart' show XFile;

import '../models/photo_model.dart';
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
  }) : _storage = storage ?? PhotoStorageService(),
       _dao = dao ?? PhotoDao(),
       _remote = remote ?? const PhotoRemoteService(),
       _connectivity = connectivity ?? ConnectivityService();

  final PhotoStorageService _storage;
  final PhotoDao _dao;
  final PhotoRemoteService _remote;
  final ConnectivityService _connectivity;

  Future<DailyPhoto?> photoOf(DateTime day) async {
    final file = await _storage.photoFor(day);
    return file == null ? null : DailyPhoto(day: day, file: file);
  }

  Future<Set<DateTime>> daysWithPhoto(List<DateTime> days) =>
      _dao.daysBetween(days.first, days.last);

  /// Saves on the phone first, so taking a photo never needs internet.
  Future<DailyPhoto> savePhoto(DateTime day, XFile photo) async {
    final file = await _storage.save(day, photo);
    await _dao.insert(day);
    return DailyPhoto(day: day, file: file);
  }


  Future<bool> uploadPending() async {
    if (!await _connectivity.isOnline()) return false;
    for (final day in await _dao.notSyncedDays()) {
      final file = await _storage.photoFor(day);
      if (file == null) continue;
      await _remote.upload(day, file);
      await _dao.markSynced(day);
    }
    return true;
  }

  Stream<bool> get onlineChanges => _connectivity.onlineChanges;
}
