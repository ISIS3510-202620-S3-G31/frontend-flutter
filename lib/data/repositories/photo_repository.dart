import 'package:camera/camera.dart' show XFile;

import '../models/photo_model.dart';
import '../services/local/photo_dao.dart';
import '../services/local/photo_storage_service.dart';

class PhotoRepository {
  PhotoRepository({PhotoStorageService? storage, PhotoDao? dao})
    : _storage = storage ?? PhotoStorageService(),
      _dao = dao ?? PhotoDao();

  final PhotoStorageService _storage;
  final PhotoDao _dao;

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
}
